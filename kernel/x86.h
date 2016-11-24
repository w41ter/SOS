#ifndef _X86_H_
#define _X86_H_

// Eflags register
#define FL_CF           0x00000001      // Carry Flag
#define FL_PF           0x00000004      // Parity Flag
#define FL_AF           0x00000010      // Auxiliary carry Flag
#define FL_ZF           0x00000040      // Zero Flag
#define FL_SF           0x00000080      // Sign Flag
#define FL_TF           0x00000100      // Trap Flag
#define FL_IF           0x00000200      // Interrupt Enable
#define FL_DF           0x00000400      // Direction Flag
#define FL_OF           0x00000800      // Overflow Flag
#define FL_IOPL_MASK    0x00003000      // I/O Privilege Level bitmask
#define FL_IOPL_0       0x00000000      //   IOPL == 0
#define FL_IOPL_1       0x00001000      //   IOPL == 1
#define FL_IOPL_2       0x00002000      //   IOPL == 2
#define FL_IOPL_3       0x00003000      //   IOPL == 3
#define FL_NT           0x00004000      // Nested Task
#define FL_RF           0x00010000      // Resume Flag
#define FL_VM           0x00020000      // Virtual 8086 mode
#define FL_AC           0x00040000      // Alignment Check
#define FL_VIF          0x00080000      // Virtual Interrupt Flag
#define FL_VIP          0x00100000      // Virtual Interrupt Pending
#define FL_ID           0x00200000      // ID flag

// Control Register flags
#define CR0_PE          0x00000001      // Protection Enable
#define CR0_MP          0x00000002      // Monitor coProcessor
#define CR0_EM          0x00000004      // Emulation
#define CR0_TS          0x00000008      // Task Switched
#define CR0_ET          0x00000010      // Extension Type
#define CR0_NE          0x00000020      // Numeric Errror
#define CR0_WP          0x00010000      // Write Protect
#define CR0_AM          0x00040000      // Alignment Mask
#define CR0_NW          0x20000000      // Not Writethrough
#define CR0_CD          0x40000000      // Cache Disable
#define CR0_PG          0x80000000      // Paging

#define CR4_PSE         0x00000010      // Page size extension

#ifndef __ASSEMBLER__

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

struct SegmentDescriptor;

static inline void lgdt(struct SegmentDescriptor *p, int size)
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

static inline void loadfs(uint16_t v)
{
    asm volatile("movw %0, %%fs" : : "r" (v));
}

static inline void loades(uint16_t v)
{
    asm volatile("movw %0, %%es" : : "r" (v));
}

static inline void loadss(uint16_t v)
{
    asm volatile("movw %0, %%ss" : : "r" (v));
}

static inline void loadds(uint16_t v)
{
    asm volatile("movw %0, %%ds" : : "r" (v));
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

#endif // !__ASM
 
#endif // !_X86_H_