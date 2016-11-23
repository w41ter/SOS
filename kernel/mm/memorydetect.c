#include "x86.h"

/**
 * detect memory in protected mode 
 * return memory size detected in KB.
 */
unsigned int ProbesMemory(void)
{
    register unsigned long *mem;
    unsigned long memCount, a;
    unsigned short memKB;
    unsigned char irq1, irq2;
    unsigned long cr0;

    /* save IRQ's */
    irq1 = inb(0x21);
    irq2 = inb(0xA1);

    /* kill all IRQ's */
    outb(0x21, 0xFF);
    outb(0xA1, 0xFF);

    memCount = 0;
    memKB = 0;

    // store a copy of CR0
	//asm volatile ("movl %%cr0, %%eax":"=a"(cr0)::"eax");
    asm volatile("movl %%cr0, %0" : "=r" (cr0));

	// invalidate the cache
	// write-back and invalidate the cache
	asm volatile ("wbinvd");

	// plug cr0 with just PE/CD/NW
	// cache disable(486+), no-writeback(486+), 32bit mode(386+)
    asm volatile("movl %0, %%cr0" : : "r" (cr0 | 0x00000001 | 0x40000000 | 0x20000000));

	do {
		memKB++;
		memCount += 1024*1024;
        mem = (unsigned long*)memCount;

		a = *mem;
		*mem = 0x55AA55AA;

        // the empty asm calls tell gcc not to rely on what's in its registers
        // as saved variables (this avoids GCC optimisations)
		asm("":::"memory");
		if (*mem != 0x55AA55AA) 
            memCount = 0;
		else {
			*mem = 0xAA55AA55;
			asm("":::"memory");
			if(*mem != 0xAA55AA55)
			memCount = 0;
		}

		asm("":::"memory");
		*mem = a;
	} while (memKB < 4096 && memCount != 0);

    asm volatile("movl %0, %%cr0" : : "r" (cr0));
//  
// 	mem_end = memKB << 20;
// 	mem = (unsigned long*) 0x413;
// 	bse_end = (*mem & 0xFFFF) <<6;
//  
	outb(0x21, irq1);
	outb(0xA1, irq2);

    return memKB;// << 20;
}