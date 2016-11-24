#include <vm.h>
#include <x86.h>
#include <trap/traps.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <driver/device.h>
#include <mm/memlayout.h>
#include <mm/physicmemory.h>

extern char end[];

static void SetupDevice(void);
static void switch_test(void);

int main(void) 
{
    SetupDevice();

    sti();

    switch_test();

    while (true) ;
}

static void SetupDevice(void)
{
    ConsoleClear();
    
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

    /* Initialize ide device */
    IDEInitialize();
}

 void
print_cur_status(void) {
    static int round = 0;
    uint16_t reg1, reg2, reg3, reg4;
    asm volatile (
            "mov %%cs, %0;"
            "mov %%ds, %1;"
            "mov %%es, %2;"
            "mov %%ss, %3;"
            : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));
    printk("%d: @ring %d\n", round, reg1 & 3);
    printk("%d:  cs = %x\n", round, reg1);
    printk("%d:  ds = %x\n", round, reg2);
    printk("%d:  es = %x\n", round, reg3);
    printk("%d:  ss = %x\n", round, reg4);
    round ++;
}

#define T_SWITCH_TO_U                120    // user/kernel switch
#define T_SWITCH_TO_K                121    // user/kernel switch

static void
switch_to_user(void) {
    //LAB1 CHALLENGE 1 : TODO
	asm volatile (
	    "sub $0x8, %%esp \n"
	    "int %0 \n"
	    "movl %%ebp, %%esp"
	    : 
	    : "i"(T_SWITCH_TO_U)
	);
}

static void
switch_to_kernel(void) {
    //LAB1 CHALLENGE 1 :  TODO
	asm volatile (
	    "int %0 \n"
        "hlt\n"
        "hlt\n"
        "hlt\n"
        "hlt\n"
        "hlt\n"
	    "movl %%ebp, %%esp \n"
	    : 
	    : "i"(T_SWITCH_TO_K)
	);
}

static void
switch_test(void) {
    print_cur_status();
    printk("+++ switch to  user  mode +++\n");
    switch_to_user();
    print_cur_status();
    printk("+++ switch to kernel mode +++\n");
    switch_to_kernel();
    print_cur_status();
}


// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PAGE_SIZE)))
pde_t entrypgdir[NPDENTRIES] = {
    // Map VA's [0, 4MB) to PA's [0, 4MB)
    [0] = (0) | PTE_P | PTE_W | PTE_PS |PTE_U,
    // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
    [KERNEL_BASE>>PDX_SHIFT] = (0) | PTE_P | PTE_W | PTE_PS |PTE_U,
};
