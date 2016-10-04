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

extern char data[];
extern char end[];

struct virtual_addr kvm;

// 内核页目录区域
pde_t kernel_pde[NPDENTRIES] __attribute__ ((aligned(PAGE_SIZE)));
// 内核 0-4M 页表区域以及设备区域 8 个
pte_t init_pte[9][NPTENTRIES] __attribute__((aligned(PAGE_SIZE)));

static void map_page(pde_t *pde, uint32_t va, 
    uint32_t pa, uint32_t flags)
{
    uint32_t pde_idx = PDX(va);
    uint32_t pte_idx = PTX(va); 
    
    pte_t *pte = (pte_t *)pde[pde_idx];
    if (!((uint32_t)pte & PTE_P)) {
        // FIXME: 这样真的好吗？
        pte = (pte_t *)V2P(kalloc()); // alloc_kernel_ppages(1);
        pde[pde_idx] = (uint32_t)pte | PTE_P | PTE_W;

        // 转换到内核线性地址并清 0
        pte = (pte_t *)P2V(pte);
        bzero(pte, PAGE_SIZE);
    } else {
        // 转换到内核线性地址
        pte = (pte_t*)((uint32_t)pte & PAGE_MASK);
        pte = (pte_t *)((uint32_t)pte + KERNEL_BASE);
    }

    pte[pte_idx] = (pa & PAGE_MASK) | PTE_P | flags;
}

static void map_range(pde_t *pde, uint32_t va,
    uint32_t pa, uint32_t size, uint32_t flags)
{
    uint32_t a, last;
    a = PGROUNDDOWN(va);
    last = PGROUNDDOWN(va + size - 1);
    printk("      map_range:[0x%08x - 0x%08x]\n", va, va + size);
    while (1) {
        map_page(pde, a, pa, flags);
        if (a >= last)
            break;
        a += PAGE_SIZE;
        pa += PAGE_SIZE;
    }
}

static void map_base_kvm(pde_t *pde)
{
    printk("  map_base_kvm: begin...\n");
    map_range(pde, KERNEL_BASE, 0, EXTMEM, PTE_W);
    map_range(pde, KERNEL_LINK, V2P(KERNEL_LINK), 
        V2P(data) - V2P(KERNEL_LINK), 0);
    map_range(pde, (uint32_t)data, V2P(data), 
        V2P(KERNEL_HEAP_START) - V2P(data), PTE_W);
    map_range(pde, DEVSPACE, DEVSPACE, 0 - DEVSPACE, PTE_W);
    printk("  map_base_kvm: end\n");
}

void kvm_init(void)
{
    // 低 4M 已经在临时页表中映射，这里也要把这 4M 映射。
    // 内核只映射 0xC0000000 及以上部分，其余部分留给 User
    kernel_pde[0] = (uint32_t)V2P(init_pte[0]) | PTE_P | PTE_W;
    kernel_pde[PDX(KERNEL_BASE)] =
        (uint32_t)V2P(init_pte[0]) | PTE_P | PTE_W;

    // 为设备准备页表
    uint32_t devspace = DEVSPACE;
    int i = 1;
    for (; i < 9; ++i) {
        kernel_pde[PDX(devspace)] = 
            (uint32_t)V2P(init_pte[i]) | PTE_P | PTE_W;
        devspace += 1024 * PAGE_SIZE;
    }
    // FIXME: 自映射覆盖了设备空间最后一页
    // 自映射
    // kernel_pde[1023] = (uint32_t)V2P(kernel_pde) | PTE_P | PTE_W;
    map_base_kvm(kernel_pde);
    //dump_page_table(kernel_pde, 1);
    switch_kvm();
}

void map(pde_t *pde, uint32_t va, uint32_t pa, uint32_t flags)
{   
    map_page(pde, va, pa, flags);

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

uint32_t *pte_ptr(uint32_t va) 
{
    uint32_t *pte = (uint32_t*)(0xffc00000 + 
        ((va & 0xffc0000) >> 10) + PTX(va) * 4);
    return pte;
}

uint32_t *pde_ptr(uint32_t va)
{
    uint32_t *pde = (uint32_t*)(0xfffff000 + PDX(va) * 4);
    return pde;
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
        map(kernel_pde, cva, pa, PTE_W);
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
    map(kernel_pde, va, pa, PTE_W);
    return va;
}

// return new alloc pde's physic address
pde_t *setup_kvm(void)
{
    printk("  setup_kvm: begin...\n");
    printk("    : kernel kvm address at: 0x%08x\n", kernel_pde);
    pde_t *pde = (pde_t*)kalloc();
    printk("    : alloca memory address at: 0x%08x\n", pde);
    if (pde == NULL)
        return NULL;
    printk("    : now try to init kalloc memory...\n");
    memset(pde, 0, PAGE_SIZE);
    printk("    : now try to map base kvm...\n");
    map_base_kvm(pde);
    return pde;
}

void switch_kvm(void)
{
    lcr3(V2P(kernel_pde));   // switch to the kernel page table
}

// Switch TSS and h/w page table to correspond to process p.
void switch_uvm(struct proc *p)
{
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
    lcr3(V2P(p->pgdir));  // switch to process's address space
    pop_cli();
}

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void init_uvm(pde_t *pgdir, char *init, uint32_t sz)
{
    char *mem;

    printk("  init_uvm: begin...\n");
    if(sz >= PAGE_SIZE)
        panic("inituvm: more than a page");
    mem = (char*)kalloc();
    memset(mem, 0, PAGE_SIZE);
    map_range(pgdir, 0, V2P(mem), PAGE_SIZE, PTE_W|PTE_U);
    memmove(mem, init, sz);
}

static void print_map(uint32_t pde_idx, uint32_t bi,
    uint32_t ei, uint32_t beg, uint32_t end)
{
    pde_idx <<= 22;
    ei <<= 12;
    bi <<= 12;
    printk("    0x%08x - 0x%08x => 0x%08x - 0x%08x\n", 
        bi | pde_idx, ei | pde_idx, beg, end);
}

void dump_page_table(pde_t *pde, int stop)
{
    printk("begin test pdentries:\n");
    uint32_t idx = 0;
    for (; idx < 1024; ++idx) {
        pte_t *pte = (pte_t *)pde[idx];
        if (!((uint32_t)pte & PTE_P))
            continue;
        pte = (pte_t*)((uint32_t)pte & PAGE_MASK);
        printk("  0x%03x00000:\n", idx << 2);
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