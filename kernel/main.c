#include <x86.h>
#include <trap/traps.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <driver/device.h>
#include <mm/vmm.h>
#include <mm/pmm.h>
#include <mm/memlayout.h>

extern char end[];

static void SetupDevice(void);

int main(void) 
{
    SetupDevice();

    sti();

    while (true) ;
}

static void SetupDevice(void)
{
    ConsoleClear();
    
    printk("Begin init kernel...\n");

    PMMInitialize();

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

    /* Initialize ide device */
    IDEInitialize();
}

// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PAGE_SIZE)))
PageDirectoryEntity entrypgdir[NPDENTRIES] = {
    // Map VA's [0, 4MB) to PA's [0, 4MB)
    [0] = (0) | PTE_P | PTE_W | PTE_PS,
    // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
    [KERNEL_BASE>>PDX_SHIFT] = (0) | PTE_P | PTE_W | PTE_PS,
};
