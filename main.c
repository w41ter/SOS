#include "console.h"
#include "debug.h"
#include "types.h"
#include "flags.h"
#include "memlayout.h"
#include "param.h"

typedef uint32_t pde_t;
pde_t entrypgdir[];  // For entry.S

int main(void) 
{
    console_clear();
    printk("Begin init kernel...");

    print_current_status();
    panic("test panic");

    while (1);
    return 0;
}

// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PGSIZE)))
pde_t entrypgdir[NPDENTRIES] = {
  // Map VA's [0, 4MB) to PA's [0, 4MB)
  [0] = (0) | PTE_P | PTE_W | PTE_PS,
  // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
  [KERNEL_BASE>>PDX_SHIFT] = (0) | PTE_P | PTE_W | PTE_PS,
};
