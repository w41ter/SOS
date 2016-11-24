#include <debug.h>
#include <vm.h>
#include <x86.h>
#include <libs/types.h>
#include <driver/console.h>
#include <driver/clock.h>
#include <trap/traps.h>
#include <mm/memlayout.h>
#include <mm/physicmemory.h>

extern char end[];

int main(void) 
{
    console_clear();
    printk("Begin init kernel...\n");

    PhysicMemoryInitialize();

    /* Initialize the 8259A interrupt controllers. */
    PICInitialize();

    /* Initialize the trap vectors */
    TrapVectrosInitialize();

    /* load trap vectors */
    IDTInitialize();

    /* Initialize clock interupt */
    ClockInitialize();

    /* Initialize keyboard interupt */
    KeyboardInitialize();

    sti();
    while (true) ;
}

// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PAGE_SIZE)))
pde_t entrypgdir[NPDENTRIES] = {
    // Map VA's [0, 4MB) to PA's [0, 4MB)
    [0] = (0) | PTE_P | PTE_W | PTE_PS,
    // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
    [KERNEL_BASE>>PDX_SHIFT] = (0) | PTE_P | PTE_W | PTE_PS,
    // FIXME: [4MB, 8MB)
    [1] = (1 << PDX_SHIFT) | PTE_P | PTE_W | PTE_PS,
    [769] = (1 << PDX_SHIFT) | PTE_P | PTE_W | PTE_PS,
};
