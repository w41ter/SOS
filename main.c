#include "console.h"
#include "debug.h"
#include "types.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "param.h"
#include "vm.h"
#include "x86.h"

pde_t entrypgdir[];  // For entry.S
extern pde_t kernel_pde[];
extern char end[];

void pic_init(void);
void idt_init(void);
void timer_init(void);
void trap_vector_init(void);

int main(void) 
{
    console_clear();
    printk("Begin init kernel...\n");

    pmm_init();
    kpde_init();

    pic_init();
    trap_vector_init();
    idt_init();

    //timer_init();

    sti();

    uint32_t test = kalloc_pages(3);
    printk("virtual address of test is: 0x%08x\n", test);
    //test_pde(kernel_pde, 1);
    //print_current_status();
    //panic("test panic");
    while (1)
        hlt();
    return 0;
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
};
