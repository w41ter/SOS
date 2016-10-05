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

typedef void (*page_map_vptr)(uint32_t, uint32_t, uint32_t);

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
        uint32_t page = alloc_kernel_ppages(1);
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

    // pde_t *pde = pde_ptr(0);
    // pte_t *pte = pte_ptr(0);
    // printk("kvm_init: kernel_pde at 0x%08x, 0x%08x, 0x%08x\n", 
    //     kernel_pde, pde, pte);
    // dump_page_table(kernel_pde, 0);
}

void mmap(uint32_t va, uint32_t pa, uint32_t flags)
{   
    page_map(va, pa, flags);

    // 通知 CPU 更新页表缓存
    asm volatile ("invlpg (%0)" : : "a" (va));
}

void unmap(pde_t *pde, uint32_t va)
{
    uint32_t pde_idx = PDX(va);
    uint32_t pte_idx = PTX(va);

    pte_t *pte = (pte_t *)(pde[pde_idx] & PAGE_MASK);

    if (!pte) {
        return;
    }

    // 转换到内核线性地址
    pte = (pte_t *)((uint32_t)pte + KERNEL_BASE);

    pte[pte_idx] = 0;

    // 通知 CPU 更新页表缓存
    asm volatile ("invlpg (%0)" : : "a" (va));
}

uint32_t get_mapping(pde_t *pde, uint32_t va, uint32_t *pa)
{
    uint32_t pde_idx = PDX(va);
    uint32_t pte_idx = PTX(va);

    pte_t *pte = (pte_t *)(pde[pde_idx] & PAGE_MASK);
    if (!pte) {
          return 0;
    }
    
    // 转换到内核线性地址
    pte = (pte_t *)((uint32_t)pte + KERNEL_BASE);

    // 如果地址有效而且指针不为NULL，则返回地址
    if (pte[pte_idx] != 0 && pa) {
         *pa = pte[pte_idx] & PAGE_MASK;
        return 1;
    }

    return 0;
}

static uint32_t alloc_kernel_vpages(uint32_t cnt)
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

static uint32_t alloc_user_vpage(void)
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
    uint32_t va = alloc_kernel_vpages(cnt);
    if (va == 0)
        return 0;
    uint32_t cva = va;
    while (cnt--) {
        uint32_t pa = alloc_kernel_ppages(1);
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

uint32_t ualloc(void)
{
    uint32_t va = alloc_user_vpage();
    if (va == 0)
        return 0;
    uint32_t pa = alloc_user_ppage();
    mmap(va, pa, PTE_W);
    return va;
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

    range_map(0, alloc_kernel_ppages(1), PAGE_SIZE, PTE_W|PTE_U);

    // 此时 0x00000000 映射到了指定位置
    memset(0, 0, PAGE_SIZE);
    memmove(0, init, sz);
    
    switch_kvm();
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
void dump_page_table(pde_t *pde, int stop)
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