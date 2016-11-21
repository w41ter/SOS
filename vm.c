#include "console.h"
#include "debug.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "proc.h"
#include "string.h"
#include "segment.h"
#include "spinlock.h"
#include "types.h"
#include "vm.h"
#include "x86.h"


struct arena {
    struct mem_block_desc *desc;
    uint32_t size;
    int G;  // if G : size = pages else: size = mem_blocks
};

struct mem_block_desc kblocks[NBLOCKDESC];

// 设备内存空间前一页用于自映射
#define SELFMAP (DEVSPACE - PAGE_SIZE)

extern char data[];
extern char end[];

struct virtual_addr kvm;

// 内核页目录区域
pde_t kernel_pde[NPDENTRIES] __attribute__ ((aligned(PAGE_SIZE)));
// 内核 0-4M 页表区域
pte_t kernel_pte[NPTENTRIES] __attribute__((aligned(PAGE_SIZE)));
// 设备区域 8 个
pte_t device_pte[8][NPTENTRIES] __attribute__((aligned(PAGE_SIZE)));

static void dump_page_table(pde_t *pde, int stop);

// 返回指定虚拟地址在页目录中页表引用
static uint32_t *pte_ptr(uint32_t va) 
{
    uint32_t pdx = PDX(SELFMAP);
    uint32_t ptx = PDX(va);
    return (uint32_t*)((pdx << 22) + (ptx << 12) + PTX(va) * 4);
}

static uint32_t *pde_ptr(uint32_t va)
{
    uint32_t pdx = PDX(SELFMAP);
    return (uint32_t*)((pdx << 22) + (pdx << 12) + PDX(va) * 4);
}

// can use in user vm.
static uint32_t virtual_to_physic(uint32_t va)
{
    uint32_t *pte = pte_ptr(va);
    return ((*pte & PAGE_MASK) + (va & ~PAGE_MASK));
}

// 将指定页面映射到当前页目录指定位置
static void page_map(uint32_t va, uint32_t pa, uint32_t flags)
{
    printk("page_map: begin map 0x%08x -> 0x%08x\n", va, pa);
    uint32_t *pde = pde_ptr(va);
    uint32_t *pte = pte_ptr(va);
    //printk("page_map: pde at: 0x%08x\n", pde);
    //printk("page_map: pte at: 0x%08x\n", pte);
    //hlt();
    
    if (!(*pde & PTE_P)) {
        uint32_t page = alloc_physic_pages(1);
        *pde = (page & PAGE_MASK) | PTE_P | PTE_W | flags;   
             // flags for PTE_U
        
        // 应为自映射，pte 地址低 12 位取零即为页表对应虚拟地址
        bzero((void*)((uint32_t)pte & PAGE_MASK), PAGE_SIZE);
    } 
    else {
        assert(!(*pte & PTE_P));
    }
    *pte = (pa & PAGE_MASK) | PTE_P | flags;
}

// 将指定区间拆分为页并映射
static void range_map(uint32_t va, uint32_t pa, 
    uint32_t size, uint32_t flags)
{
    uint32_t a, last;
    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);
    //printk("      map_range:[0x%08x - 0x%08x]\n", va, va + size);
    while (1) {
        page_map(a, pa, flags);
        if (a >= last)
            break;
        a += PAGE_SIZE;
        pa += PAGE_SIZE;
    }
}

static void kernel_init_page_map(uint32_t va, 
    uint32_t pa, uint32_t flags)
{
    uint32_t pdx = kernel_pde[PDX(va)];
    if (!((uint32_t)pdx & PTE_P))
        panic("kernel_init_page_map: page"  \
            " table entries not exists!\n");
    pte_t *pte = (pte_t*)(pdx & PAGE_MASK);
    pte[PTX(va)] = (pa & PAGE_MASK) | PTE_P | flags;
}

static void kernel_init_range_map(uint32_t va, uint32_t pa, 
    uint32_t size, uint32_t flags)
{
    uint32_t a, last;
    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);
    while (1) {
        kernel_init_page_map(a, pa, flags);
        if (a >= last)
            break;
        a += PAGE_SIZE;
        pa += PAGE_SIZE;
    }
}

void kvm_init(void)
{
    // 低 4M 已经在临时页表中映射，这里也要把这 4M 映射。
    kernel_pde[0] = (uint32_t)V2P(kernel_pte) | PTE_P | PTE_W;
    kernel_pde[PDX(KERNEL_BASE)] =
         (uint32_t)V2P(kernel_pte) | PTE_P | PTE_W;
    
    // 为设备准备页表
    uint32_t devspace = DEVSPACE;
    int i = 0;
    for (; i < 8; ++i) {
        kernel_pde[PDX(devspace)] = 
            (uint32_t)V2P(device_pte[i]) | PTE_P | PTE_W;
        devspace += 1024 * PAGE_SIZE;
    }

    // 自映射
    kernel_pde[PDX(SELFMAP)] = (uint32_t)V2P(kernel_pde) | PTE_P | PTE_W;
    
    kernel_init_range_map(KERNEL_BASE, 0, EXTMEM, PTE_W);
    kernel_init_range_map(KERNEL_LINK, V2P(KERNEL_LINK), 
        V2P(data) - V2P(KERNEL_LINK), 0);
    kernel_init_range_map((uint32_t)data, V2P(data), 
        V2P(KERNEL_HEAP_START) - V2P(data), PTE_W);
    kernel_init_range_map(DEVSPACE, DEVSPACE, 0 - DEVSPACE, PTE_W);

    switch_kvm();
    
    block_desc_init(kblocks);
    // pde_t *pde = pde_ptr(0);
    // pte_t *pte = pte_ptr(0);
    // printk("kvm_init: kernel_pde at 0x%08x, 0x%08x, 0x%08x\n", 
    //     kernel_pde, pde, pte);
    dump_page_table(kernel_pde, 1);
}

void mmap(uint32_t va, uint32_t pa, uint32_t flags)
{   
    page_map(va, pa, flags);

    // 通知 CPU 更新页表缓存
    asm volatile ("invlpg (%0)" : : "a" (va));
}

void unmap(uint32_t va)
{
    uint32_t *pte = pte_ptr(va);
    *pte &= ~PTE_P;

    // 通知 CPU 更新页表缓存
    asm volatile ("invlpg (%0)" : : "a" (va));
}


// switch to page dir entries, must be virtual address. 
static inline void switch_to_vm(pde_t *pde)
{
    assert(pde);

    lcr3(V2P(pde));
}

// return new alloc pde's physic address
pde_t *setup_kvm(void)
{
    printk("  setup_kvm: begin...\n");
    pde_t *pde = (pde_t*)kalloc();
    if (pde == NULL)
        return NULL;
    bzero(pde, PAGE_SIZE);

    // just copy [0xc0000000, 0)
    memcpy(pde + 768, kernel_pde + 768, 1024);
    pde[PDX(SELFMAP)] = (uint32_t)V2P(pde) | PTE_P | PTE_W;

    // printk("  setup_kvm: page dir entry at 0x%08x\n", pde);
    // dump_page_table(pde, 0);

    return pde;
}

void switch_kvm(void)
{
    switch_to_vm(kernel_pde);   // switch to the kernel page table
    //lcr3(V2P(kernel_pde));   
}

// Switch TSS and h/w page table to correspond to process p.
void switch_uvm(struct proc *p)
{   
    printk("  switch_uvm: begin...\n");
    push_cli();
    cpu->gdt[SEG_TSS] = SEG16(STS_T32A, &cpu->ts, sizeof(cpu->ts)-1, 0);
    cpu->gdt[SEG_TSS].s = 0;
    cpu->ts.ss0 = SEG_KDATA << 3;
    cpu->ts.esp0 = (uint32_t)proc->kstack + KSTACKSIZE;
    // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
    // forbids I/O instructions (e.g., inb and outb) from user space
    cpu->ts.iomb = (uint16_t) 0xFFFF;
    ltr(SEG_TSS << 3);
    if(p->pgdir == 0)
        panic("switchuvm: no pgdir");
    switch_to_vm(p->pgdir); // switch to process's address space
    pop_cli();
    printk("  switch_uvm: end\n");
}

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void init_uvm(pde_t *pgdir, char *init, uint32_t sz)
{
    printk("  init_uvm: begin...\n");
    if(sz >= PAGE_SIZE)
        panic("inituvm: more than a page");
    // 先切换到用户页目录，避免将内存安装到内核页目录
    switch_to_vm(pgdir);

    range_map(0, alloc_physic_pages(1), PAGE_SIZE, PTE_W|PTE_U);

    // 此时 0x00000000 映射到了指定位置
    memset(0, 0, PAGE_SIZE);
    memmove(0, init, sz);
    
    switch_kvm();
}

// Free a page table and all the physical memory pages
// in the user part.
void free_vm(pde_t *pgdir)
{
    uint32_t i;

    if (pgdir == 0)
        panic("freevm: no pgdir");
    for (i = 0; i < NPDENTRIES; i++) {
        if (pgdir[i] & PTE_P) {
            uint32_t v = (uint32_t)P2V(PTE_ADDR(pgdir[i]));
            kfree_pages(v, 1);
        }
    }
    kfree_pages((uint32_t)pgdir, 1);
}

// Given a parent process's page table, create a copy
// of it for a child.
pde_t *copy_uvm(pde_t *pgdir)
{
    pde_t *pde = (pde_t*)kalloc();
    if (pde == NULL)
        return NULL;
    memcpy(pde, pgdir, PAGE_SIZE);
    return pde;
}

static void print_map(uint32_t pde_idx, uint32_t bi,
    uint32_t ei, uint32_t beg, uint32_t end)
{
    pde_idx <<= 22;
    ei <<= 12;
    bi <<= 12;
    printk("    [0x%08x - 0x%08x) => [0x%08x - 0x%08x)\n", 
        bi + pde_idx, ei + pde_idx, beg, end);
}

// notice: 有很多没有直接映射页表的页面会导致访问出错
static void dump_page_table(pde_t *pde, int stop)
{
    printk("dump_page_table:\n");
    uint32_t idx = 0;
    for (; idx < 1024; ++idx) {
        pte_t *pte = (pte_t *)pde[idx];
        if (!((uint32_t)pte & PTE_P))
            continue;
        pte = (pte_t*)((uint32_t)pte & PAGE_MASK);
        printk("  [%d] 0x%03x00000 => 0x%08x:\n", idx, idx << 2, pte);
        uint32_t ti = 0;
        int32_t begin = -1, last = 0, beg_idx = 0;
        for (; ti < 1024; ++ti) {
            uint32_t page = pte[ti];
            if (!(page & PTE_P)) {
                if (begin != -1) {
                    print_map(idx, beg_idx, ti, begin, last);
                    begin = -1;
                }
                continue;
            }
            page = page & PAGE_MASK;
            if (begin == -1) {
                begin = page;
                last = begin + 0x1000;
                beg_idx = ti;
            }
            else if (last != page) {
                print_map(idx, beg_idx, ti, begin, last);
                begin = page;
                last = begin + 0x1000; 
                beg_idx = ti;  
            }
            else 
                last = page + 0x1000;
        }
        if (begin != -1)
           print_map(idx, beg_idx, 2014, begin, last);
    }
    while (!stop) {
        hlt();
    }
}

static uint32_t alloc_kernel_virtual_pages(uint32_t cnt)
{
    // printk("try to allocate virtual page: %d\n", cnt);
    int32_t vaddr_start = 0, bit_idx_start = -1;
    bit_idx_start = bitmap_scan(&kvm.bitmap, cnt);
    if (bit_idx_start == -1)
        return 0;
    uint32_t idx = 0;
    for (; idx < cnt; ++idx) {
        bitmap_set(&kvm.bitmap, bit_idx_start + idx, 1);
    }
    vaddr_start = kvm.start + bit_idx_start * PAGE_SIZE;
    return vaddr_start;
}

static uint32_t alloc_user_virtual_pages(uint32_t cnt)
{
    int32_t vaddr_start = 0, bit_idx_start = -1;
    bit_idx_start = bitmap_scan(&proc->va.bitmap, 1);
    if (bit_idx_start == -1)
        return 0;
    bitmap_set(&proc->va.bitmap, bit_idx_start, 1);
    vaddr_start = proc->va.start + bit_idx_start * PAGE_SIZE;
    return vaddr_start;
}

uint32_t kalloc_pages(uint32_t cnt)
{
    assert(cnt > 0 && cnt < 2048);
    uint32_t va = alloc_kernel_virtual_pages(cnt);
    if (va == 0)
        return 0;
    uint32_t cva = va;
    while (cnt--) {
        uint32_t pa = alloc_physic_pages(1);
        if (pa == 0) {
            // TODO: 回收内存
            return 0;
        }
        mmap(cva, pa, PTE_W);
        cva += PAGE_SIZE;
    }
    return va;
}

uint32_t kalloc(void)
{
    return kalloc_pages(1);
}

uint32_t ualloc_pages(uint32_t n)
{
    assert(n > 0 && n < 2048);
    uint32_t va = alloc_user_virtual_pages(n);
    if (va == 0)
        return 0;
    uint32_t cva = va;
    while (n--) {
        uint32_t pa = alloc_physic_pages(1);
        if (pa == 0) {
            // TODO: 回收内存
            return 0;
        }
        mmap(cva, pa, PTE_W);
        cva += PAGE_SIZE;
    }
    return va;
}

uint32_t ualloc(void)
{
    return ualloc_pages(1);
}

static void free_kernel_virtual_pages(uint32_t va, uint32_t size)
{
    uint32_t bit_idx_start = 0, n = 0;
    bit_idx_start = (va-kvm.start) / PAGE_SIZE;
    while (n < size) {
        bitmap_set(&kvm.bitmap, bit_idx_start + n++, 0);
    }
}

static void free_user_virtual_pages(uint32_t va, uint32_t size)
{
    uint32_t bit_idx_start = 0, n = 0;
    bit_idx_start = (va-proc->va.start) / PAGE_SIZE;
    while (n < size) {
        bitmap_set(&kvm.bitmap, bit_idx_start + n++, 0);
    }
}

void kfree_pages(uint32_t va, uint32_t size)
{
    uint32_t n = 0, tmp = va;
    while (n < size) {
        tmp += PAGE_SIZE;
        // FIXME: v2p
        free_physic_pages(virtual_to_physic(tmp), 1);
        unmap(tmp);
        ++n;
    }
    free_kernel_virtual_pages(va, size);
}

void ufree_pages(uint32_t va, uint32_t size)
{
    uint32_t n = 0, tmp = va;
    while (n < size) {
        tmp += PAGE_SIZE;
        // FIXME: v2p
        free_physic_pages(virtual_to_physic(tmp), 1);
        unmap(tmp);
        ++n;
    }
    free_user_virtual_pages(va, size);
}

static struct mem_block *arena_to_block(struct arena *a, uint32_t idx)
{
    return (struct mem_block*)((uint32_t)a + sizeof(struct arena)
        + idx * a->desc->size);
}

static struct arena *block_to_arena(struct mem_block *b)
{
    return (struct arena*)((uint32_t)b & PAGE_MASK);
}

static void* mem_block_alloc_pages(uint32_t size)
{
    struct arena *a;
    uint32_t need_nums = PGROUNDUP(size + sizeof(struct arena));
    a = (struct arena *)ualloc_pages(need_nums);
    if (a != NULL) {
        bzero(a, PAGE_SIZE * need_nums);
        a->desc = NULL;
        a->size = need_nums;
        a->G = 1;
        return a + 1;
    }
    return NULL;
}

static uint32_t mem_block_find_fit_block(
    struct mem_block_desc *descs, uint32_t size)
{
    uint8_t idx;
    for (idx = 0; idx < NBLOCKDESC; ++idx) {
        if (size <= descs[idx].size)
            break;
    }
    assert(idx < NBLOCKDESC);
    return idx;
}

// must hold be acquire 
static int mem_block_try_expand_free_list(
    struct mem_block_desc *desc)
{
    assert(desc);

    struct arena *a;
    uint32_t block_idx;
    if (list_empty(&desc->free_list)) {
        a = (struct arena *)ualloc();
        if (a == NULL)
            return 0;
        bzero(a, PAGE_SIZE);
        a->desc = desc;
        a->G = 0;
        a->size = desc->total;
        for (block_idx = 0; block_idx < a->size; ++block_idx) {
            list_append(&desc->free_list, 
                &arena_to_block(a, block_idx)->node);
        }
    }
    return 1;
}

int sys_malloc(uint32_t size)
{
    uint32_t idx;
    struct arena *a;
    struct mem_block *block;
    struct mem_block_desc *descs = proc->ublocks;
    
    if (size > 1024) {
        return (int)mem_block_alloc_pages(size);
    }
    idx = mem_block_find_fit_block(descs, size);

    acquire(&descs[idx].lock);
    if (!mem_block_try_expand_free_list(&descs[idx])) {
        release(&descs[idx].lock);
        return 0;
    }
    struct list_node *node = list_head(&(descs[idx].free_list));
    block = list_get(node, struct mem_block, node);
    memset(block, 0, descs[idx].size);
    a = block_to_arena(block);
    a->size--;
    release(&descs[idx].lock);

    return (int)block;
}

int sys_free(void *ptr)
{
    struct arena *a;
    struct mem_block *block;

    if (ptr == NULL)
        return 0;
    
    block = (struct mem_block*)ptr;
    a = block_to_arena(block);
    if (a->G) {
        ufree_pages((uint32_t)a, a->size);
        return 0;
    }

    acquire(&a->desc->lock);
    list_append(&a->desc->free_list, &block->node);
    if (++a->size == a->desc->total) {
        uint32_t idx;
        for (idx = 0; idx < a->desc->total; ++idx) {
            block = arena_to_block(a, idx);
            list_remove(&block->node);
        }
        ufree_pages((uint32_t)a, 1);
    }
    release(&a->desc->lock);
    return 0;    
}

void block_desc_init(struct mem_block_desc *desc)
{
    uint16_t idx, size = 16;
    for (idx = 0; idx < NBLOCKDESC; ++idx) {
        desc[idx].size = size;
        desc[idx].total = (PAGE_SIZE-sizeof(struct arena)) / size;
        list_init(&desc[idx].free_list);
        init_lock(&desc[idx].lock, "mem_block_desc");
        size <<= 1; 
    }
}
