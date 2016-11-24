#ifndef _X86_H_
#define _X86_H_

#include <libs/types.h>

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

struct GateDescriptor;

static inline void lidt(struct GateDescriptor *p, int size)
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

#endif // !_X86_H_