#ifndef _SEGMENT_H_
#define _SEGMENT_H_

// various segment selectors.
#define SEG_KCODE 1  // kernel code
#define SEG_KDATA 2  // kernel data+stack
//#define SEG_KCPU  3  // kernel per-cpu data
#define SEG_UCODE 3  // user code
#define SEG_UDATA 4  // user data+stack
#define SEG_TSS   5  // this process's task state

// gdt[NSEGS] holds the above segments.
#define NSEGS     6

/* global descriptor numbers */
#define GD_KCODE    ((SEG_KCODE) << 3)        // kernel text
#define GD_KDATA    ((SEG_KDATA) << 3)        // kernel data
#define GD_UCODE    ((SEG_UCODE) << 3)        // user text
#define GD_UDATA    ((SEG_UDATA) << 3)        // user data
#define GD_TSS      ((SEG_TSS) << 3)          // task segment selector

#define DPL_KERNEL  0x0     // kernel DPL
#define DPL_USER    0x3     // User DPL

#define KERNEL_CS    ((GD_KCODE) | DPL_KERNEL)
#define KERNEL_DS    ((GD_KDATA) | DPL_KERNEL)
#define USER_CS      ((GD_UCODE) | DPL_USER)
#define USER_DS      ((GD_UDATA) | DPL_USER)

#ifndef __ASSEMBLER__

#include <libs/types.h>

// Segment Descriptor
typedef struct SegmentDescriptor {
    int32_t lim_15_0 : 16;  // Low bits of segment limit
    int32_t base_15_0 : 16; // Low bits of segment base address
    int32_t base_23_16 : 8; // Middle bits of segment base address
    int32_t type : 4;       // Segment type (see STS_ constants)
    int32_t s : 1;          // 0 = system, 1 = application
    int32_t dpl : 2;        // Descriptor Privilege Level
    int32_t p : 1;          // Present
    int32_t lim_19_16 : 4;  // High bits of segment limit
    int32_t avl : 1;        // Unused (available for software use)
    int32_t rsv1 : 1;       // Reserved
    int32_t db : 1;         // 0 = 16-bit segment, 1 = 32-bit segment
    int32_t g : 1;          // Granularity: limit scaled by 4K when set
    int32_t base_31_24 : 8; // High bits of segment base address
} SegmentDescriptor;

#define SEG_NULL                                            \
    (SegmentDescriptor) {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

// Normal segment
#define SEG(type, base, lim, dpl)                           \
    (SegmentDescriptor) {                                      \
        ((lim) >> 12) & 0xffff, (base) & 0xffff,            \
        ((base) >> 16) & 0xff, type, 1, dpl, 1,             \
        (unsigned)(lim) >> 28, 0, 0, 1, 1,                  \
        (unsigned) (base) >> 24                             \
    }

#define SEGTSS(type, base, lim, dpl)                        \
    (SegmentDescriptor) {                                      \
        (lim) & 0xffff, (base) & 0xffff,                    \
        ((base) >> 16) & 0xff, type, 0, dpl, 1,             \
        (unsigned) (lim) >> 16, 0, 0, 1, 0,                 \
        (unsigned) (base) >> 24                             \
    }


/** 
 * task state segment format (as described 
 * by the Pentium architecture book) 
 */
typedef struct TaskState {
    uint32_t link;       // old ts selector
    uintptr_t esp0;      // stack pointers and segment selectors
    uint16_t ss0;        // after an increase in privilege level
    uint16_t padding1;
    uintptr_t esp1;
    uint16_t ss1;
    uint16_t padding2;
    uintptr_t esp2;
    uint16_t ss2;
    uint16_t padding3;
    uintptr_t cr3;       // page directory base
    uintptr_t eip;       // saved state from last task switch
    uint32_t eflags;
    uint32_t eax;        // more saved state (registers)
    uint32_t ecx;
    uint32_t edx;
    uint32_t ebx;
    uintptr_t esp;
    uintptr_t ebp;
    uint32_t esi;
    uint32_t edi;
    uint16_t es;         // even more saved state (segment selectors)
    uint16_t padding4;
    uint16_t cs;
    uint16_t padding5;
    uint16_t ss;
    uint16_t padding6;
    uint16_t ds;
    uint16_t padding7;
    uint16_t fs;
    uint16_t padding8;
    uint16_t gs;
    uint16_t padding9;
    uint16_t ldt;
    uint16_t padding10;
    uint16_t t;          // trap on task switch
    uint16_t iomb;       // i/o map base address
} __attribute__((packed)) TaskState;

void GDTInitialize(void);

#endif


// Application segment type bits
#define STA_X       0x8     // Executable segment
#define STA_E       0x4     // Expand down (non-executable segments)
#define STA_C       0x4     // Conforming code segment (executable only)
#define STA_W       0x2     // Writeable (non-executable segments)
#define STA_R       0x2     // Readable (executable segments)
#define STA_A       0x1     // Accessed

// System segment type bits
#define STS_T16A    0x1     // Available 16-bit TSS
#define STS_LDT     0x2     // Local Descriptor Table
#define STS_T16B    0x3     // Busy 16-bit TSS
#define STS_CG16    0x4     // 16-bit Call Gate
#define STS_TG      0x5     // Task Gate / Coum Transmitions
#define STS_IG16    0x6     // 16-bit Interrupt Gate
#define STS_TG16    0x7     // 16-bit Trap Gate
#define STS_T32A    0x9     // Available 32-bit TSS
#define STS_T32B    0xB     // Busy 32-bit TSS
#define STS_CG32    0xC     // 32-bit Call Gate
#define STS_IG32    0xE     // 32-bit Interrupt Gate
#define STS_TG32    0xF     // 32-bit Trap Gate

#endif