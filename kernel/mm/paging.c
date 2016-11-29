#include <x86.h>
#include <mm/vmm.h>
#include <mm/memlayout.h>
#include <mm/bootallocator.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <libs/stdio.h>

static PageDirectoryEntity *pgdir;

extern uint32_t memorySize;

static bool IsPagePersent(uint32_t page) 
{
    return page & PTE_P;
}

static bool IsLargePage(uint32_t page) 
{
    return page & PTE_PS;
}

void PagingInitialize(void) 
{
    printk(" [+] setup paging.\n");

    pgdir = P2V(BootAllocPage());

    assert(pgdir != NULL);

    /* clear page dir */
    memset(pgdir, 0, PAGE_SIZE);

    uint32_t topAddr = memorySize > V2P(KERNEL_TOP)
        ? V2P(KERNEL_TOP) : memorySize;
    
    topAddr = 0x1000000;

    /* Clear virtual address's [0, 4MB) to physical address's [0, 4MB) map */
    pgdir[0] = PTE_P | PTE_W | PTE_PS;

    /*
     * Map [0, topAddr) to [KERNEL_BASE, KERNEL_BAST + topAddr)
     */
    printk("  [+] now to map [0, 0x%08x) to [0x%08x, 0x%08x)\n",
        topAddr, P2V(0), P2V(topAddr));
    for (uint32_t phyAddr = 0; phyAddr < topAddr;) {
        uint32_t virtualAddr = (uint32_t)P2V(phyAddr);

        PageTableEntity *pgtab = P2V(BootAllocPage());
        assert(pgtab != NULL);
        memset(pgtab, 0, PAGE_SIZE);

        /* Fill all entries of page table */
        uint32_t tmpVirtualAddr = virtualAddr;
        for (size_t i = 0; i < NPDENTRIES; ++i) {
            pgtab[PTX(tmpVirtualAddr)] = (phyAddr & PAGE_MASK) | PTE_P | PTE_W;
            tmpVirtualAddr += PAGE_SIZE;
            phyAddr += PAGE_SIZE;
            if (phyAddr >= topAddr) 
                break;
        }

        /* Fill page directory entry */
        pgdir[PDX(virtualAddr)] = (V2P(pgtab) & PAGE_MASK) | PTE_P | PTE_W;
    }

    /* Refresh paging directory */
    lcr3(V2P(pgdir));
    
    // PrintPageDirectory(pgdir);
    // hlt();
}

static void PrintMap(uint32_t pde_idx, uint32_t bi,
    uint32_t ei, uint32_t beg, uint32_t end)
{
    pde_idx <<= 22;
    ei <<= 12;
    bi <<= 12;
    printk("  |-- [0x%08x - 0x%08x) => [0x%08x - 0x%08x)\n", 
        bi + pde_idx, ei + pde_idx, beg, end);
}

void PrintPageDirectory(PageDirectoryEntity *pde)
{
    printk("-------------------- BEGIN --------------------\n");
    for (uint32_t idx = 0; idx < NPDENTRIES; ++idx) {
        PageTableEntity *pte = (PageTableEntity*)pde[idx];
        if (!IsPagePersent((uint32_t)pte))
            continue;
        
        if (IsLargePage((uint32_t)pte)) {
            uint32_t addr = (uint32_t)pte & PAGE_MASK;
            printk("[%d] [0x%08x, 0x%08x) => [0x%08x, 0x%08x)\n", 
                idx, PGADDR(idx, 0, 0), PGADDR(idx+1, 0, 0), 
                addr, addr + 0x100000);
            continue;
        }

        /* dump page table entry */
        pte = (PageTableEntity*)((uint32_t)pte & PAGE_MASK);
        pte = P2V(pte);
        printk("[%d] 0x%03x00000 at 0x%08x:\n", idx, idx << 2, pte);
        int32_t begin = -1, last = 0, beg_idx = 0;
        for (uint32_t ti = 0; ti < NPTENTRIES; ++ti) {
            uint32_t page = pte[ti];
            if (!IsPagePersent(page)) {
                if (begin != -1) {
                    PrintMap(idx, beg_idx, ti, begin, last);
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
                PrintMap(idx, beg_idx, ti, begin, last);
                begin = page;
                last = begin + 0x1000; 
                beg_idx = ti;  
            }
            else 
                last = page + 0x1000;
        }
        if (begin != -1)
           PrintMap(idx, beg_idx, 2014, begin, last);
    }
    printk("--------------------- END ---------------------\n");
}

uintptr_t GetInitializePageDirctory(void)
{
    assert(pgdir && "pgdir is nullptr");
    return V2P(pgdir);
}

void OnPageFault(TrapFrame *tf)
{
    /* error_code:
     * bit 0 == 0 means no page found, 1 means protection fault
     * bit 1 == 0 means read, 1 means write
     * bit 2 == 0 means kernel, 1 means user
     * */
    printk("page fault at 0x%08x, eip=0x%08x: %c/%c [%s].\n", 
            rcr2(), tf->eip,
            (tf->err & 4) ? 'U' : 'K',
            (tf->err & 2) ? 'W' : 'R',
            (tf->err & 1) ? "protection fault" : "no page found");
    panic("");
}