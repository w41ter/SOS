#ifndef _MEM_LAYOUT_H_
#define _MEM_LAYOUT_H_

// Memory layout

#define EXTMEM  0x100000            // Start of extended memory
#define END_EXTMEM 0x400000         // End of extended memory
#define PHYSTOP 0xE000000           // Top physical memory
#define DEVSPACE 0xFE000000         // Other devices are at high addresses

#define KERNEL_SIZE 0x38000000      // Kernel size
#define KERNEL_BASE 0xc0000000      // First kernel virtual address
#define KERNEL_TOP  0xF8000000      // Kernel max high address
#define KERNEL_LINK (KERNEL_BASE+EXTMEM)  // Address where kernel is linked

#define V2P(a) (((uint32_t) (a)) - KERNEL_BASE)
#define P2V(a) (((void *) (a)) + KERNEL_BASE)

#define V2P_WO(x) ((x) - KERNEL_BASE)    // same as V2P, but without casts
#define P2V_WO(x) ((x) + KERNEL_BASE)    // same as P2V, but without casts

#endif // _MEM_LAYOUT_H_
