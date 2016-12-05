#include <x86.h>
#include <mm/mm.h>
#include <trap/traps.h>
#include <libs/ulib.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <driver/device.h>
#include <proc/proc.h>
#include <proc/spinlock.h>
#include <proc/schedule.h>
#include <fs/filesystem.h>

extern char end[];

static void SetupDevice(void);
static void Idle(void);

extern void Test(void);

int main(void) 
{
    ConsoleClear();
    
    printk("Begin init kernel...\n");

    /* Initialize physic memory manager */
    SetupPhysicMemoryManager();

    SetupDevice();

    SetupVirtualMemoryManager();

    SetupFileSystem();

    SetupProcessManager();

    SetupScheduleManager();
    
    Idle();
}

static void SetupDevice(void)
{
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

static void Idle(void)
{
    extern void ProcessClearTerminated(void);

    PopClearInterupt();     /* see spinlock.c */
    while (true) {
        ProcessClearTerminated();
        hlt();
    }
}

// The boot page table used in entry.S.
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
