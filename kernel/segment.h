#ifndef _SEGMENT_H_
#define _SEGMENT_H_

// various segment selectors.
#define SEG_KCODE 1  // kernel code
#define SEG_KDATA 2  // kernel data+stack
#define SEG_KCPU  3  // kernel per-cpu data
#define SEG_UCODE 4  // user code
#define SEG_UDATA 5  // user data+stack
#define SEG_TSS   6  // this process's task state

// cpu->gdt[NSEGS] holds the above segments.
#define NSEGS     7

#ifndef __ASSEMBLER__

#include <libs/types.h>

// Segment Descriptor
struct segdesc {
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
};

// Normal segment
#define SEG(type, base, lim, dpl) (struct segdesc)    \
{ ((lim) >> 12) & 0xffff, (int32_t)(base) & 0xffff,      \
  ((int32_t)(base) >> 16) & 0xff, type, 1, dpl, 1,       \
  (int32_t)(lim) >> 28, 0, 0, 1, 1, (int32_t)(base) >> 24 }
#define SEG16(type, base, lim, dpl) (struct segdesc)  \
{ (lim) & 0xffff, (int32_t)(base) & 0xffff,              \
  ((int32_t)(base) >> 16) & 0xff, type, 1, dpl, 1,       \
  (int32_t)(lim) >> 16, 0, 0, 1, 0, (int32_t)(base) >> 24 }
#endif

#define DPL_USER    0x3     // User DPL

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