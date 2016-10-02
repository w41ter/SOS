#include "console.h"
#include "debug.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "string.h"
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

static void map_inner(pde_t *pde, uint32_t va, 
    uint32_t pa, uint32_t flags)
{
    uint32_t pde_idx = PDX(va);
    uint32_t pte_idx = PTX(va); 
    
        //printk("0x%0x8\n", va);
    pte_t *pte = (pte_t *)pde[pde_idx];
    if (!((uint32_t)pte & PTE_P)) {
        assert(0);
        pte = (pte_t *)alloc_kernel_ppages(1);
        pde[pde_idx] = (uint32_t)pte | PTE_P | PTE_W;

        // 转换到内核线性地址并清 0
        pte = (pte_t *)((uint32_t)pte + KERNEL_BASE);
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
    while (1) {
        map_inner(pde, a, pa, flags);
        if (a >= last)
            break;
        a += PAGE_SIZE;
        pa += PAGE_SIZE;
    }
}

void switch_kpde(void)
{
    lcr3(V2P(kernel_pde));   // switch to the kernel page table
}

void kpde_init(void)
{
    // 低 4M 已经在临时页表中映射，这里也要把这 4M 映射。
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

    map_range(kernel_pde, KERNEL_BASE, 0, EXTMEM, PTE_W);
    map_range(kernel_pde, KERNEL_LINK, V2P(KERNEL_LINK), 
        V2P(data) - V2P(KERNEL_LINK), 0);
    map_range(kernel_pde, (uint32_t)data, V2P(data), 
        V2P(KERNEL_HEAP_START) - V2P(data), PTE_W);
    map_range(kernel_pde, DEVSPACE, DEVSPACE, 0 - DEVSPACE, PTE_W);
    test_pde(kernel_pde, 1);
    switch_kpde();
}

void map(pde_t *pde, uint32_t va, uint32_t pa, uint32_t flags)
{   
    map_inner(pde, va, pa, flags);

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

uint32_t alloc_kernel_vpages(uint32_t cnt)
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

static void print_map(uint32_t pde_idx, uint32_t bi,
    uint32_t ei, uint32_t beg, uint32_t end)
{
    pde_idx <<= 22;
    ei <<= 12;
    bi <<= 12;
    printk("    0x%08x - 0x%08x => 0x%08x - 0x%08x\n", 
        bi | pde_idx, ei | pde_idx, beg, end);
}

void test_pde(pde_t *pde, int stop)
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