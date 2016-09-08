#ifndef _X86_H_
#define _X86_H_

#include "types.h"
// Routines to let C code use special x86 instructions.

static inline uint8_t inb(uint16_t port)
{
    uint8_t data;

    asm volatile("in %1,%0" : "=a" (data) : "d" (port));
    return data;
}

static inline void insl(int port, void *addr, int cnt)
{
    asm volatile("cld; rep insl" :
                             "=D" (addr), "=c" (cnt) :
                             "d" (port), "0" (addr), "1" (cnt) :
                             "memory", "cc");
}

static inline void outb(uint16_t port, uint8_t data)
{
    asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void outw(uint16_t port, uint16_t data)
{
    asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void outsl(int port, const void *addr, int cnt)
{
    asm volatile("cld; rep outsl" :
                             "=S" (addr), "=c" (cnt) :
                             "d" (port), "0" (addr), "1" (cnt) :
                             "cc");
}

static inline void stosb(void *addr, int data, int cnt)
{
    asm volatile("cld; rep stosb" :
                             "=D" (addr), "=c" (cnt) :
                             "0" (addr), "1" (cnt), "a" (data) :
                             "memory", "cc");
}

static inline void stosl(void *addr, int data, int cnt)
{
    asm volatile("cld; rep stosl" :
                             "=D" (addr), "=c" (cnt) :
                             "0" (addr), "1" (cnt), "a" (data) :
                             "memory", "cc");
}

struct segdesc;

static inline void lgdt(struct segdesc *p, int size)
{
    volatile uint16_t pd[3];

    pd[0] = size-1;
    pd[1] = (uint32_t)p;
    pd[2] = (uint32_t)p >> 16;

    asm volatile("lgdt (%0)" : : "r" (pd));
}

struct gate_desc;

static inline void lidt(struct gate_desc *p, int size)
{
    volatile uint16_t pd[3];

    pd[0] = size-1;
    pd[1] = (uint32_t)p;
    pd[2] = (uint32_t)p >> 16;

    asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void ltr(uint16_t sel)
{
    asm volatile("ltr %0" : : "r" (sel));
}

static inline uint32_t readeflags(void)
{
    uint32_t eflags;
    asm volatile("pushfl; popl %0" : "=r" (eflags));
    return eflags;
}

static inline void loadgs(uint16_t v)
{
    asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void cli(void)
{
    asm volatile("cli");
}

static inline void sti(void)
{
    asm volatile("sti");
}

static inline uint32_t xchg(volatile uint32_t *addr, uint32_t newval)
{
    uint32_t result;

    // The + in "+m" denotes a read-modify-write operand.
    asm volatile("lock; xchgl %0, %1" :
                             "+m" (*addr), "=a" (result) :
                             "1" (newval) :
                             "cc");
    return result;
}

static inline uint32_t rcr2(void)
{
    uint32_t val;
    asm volatile("movl %%cr2,%0" : "=r" (val));
    return val;
}

static inline void lcr3(uint32_t val)
{
    asm volatile("movl %0,%%cr3" : : "r" (val));
}

static inline void hlt(void)
{
    __asm__ volatile ("hlt");
}


// Layout of the trap frame built on the stack by the
// hardware and by trapasm.S, and passed to trap().
struct trap_frame {
	// registers as pushed by pusha
	uint32_t edi;
	uint32_t esi;
	uint32_t ebp;
	uint32_t oesp;      // useless & ignored
	uint32_t ebx;
	uint32_t edx;
	uint32_t ecx;
	uint32_t eax;

	// rest of trap frame
	uint16_t gs;
	uint16_t padding1;
	uint16_t fs;
	uint16_t padding2;
	uint16_t es;
	uint16_t padding3;
	uint16_t ds;
	uint16_t padding4;
	uint32_t trapno;

	// below here defined by x86 hardware
	uint32_t err;
	uint32_t eip;
	uint16_t cs;
	uint16_t padding5;
	uint32_t eflags;

	// below here only when crossing rings, such as from user to kernel
	uint32_t esp;
	uint16_t ss;
	uint16_t padding6;
};

#endif // !_X86_H_