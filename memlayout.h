#ifndef _MEM_LAYOUT_H_
#define _MEM_LAYOUT_H_

// Memory layout

#define EXTMEM  0x100000            // Start of extended memory
#define PHYSTOP 0xE000000           // Top physical memory
#define DEVSPACE 0xFE000000         // Other devices are at high addresses

// Key addresses for address space layout (see kmap in vm.c for layout)
#define KERNEL_BASE 0xc0000000         // First kernel virtual address
#define KERNEL_LINK (KERNEL_BASE+EXTMEM)  // Address where kernel is linked

#define V2P(a) (((uint) (a)) - KERNEL_BASE)
#define P2V(a) (((void *) (a)) + KERNEL_BASE)

#define V2P_WO(x) ((x) - KERNEL_BASE)    // same as V2P, but without casts
#define P2V_WO(x) ((x) + KERNEL_BASE)    // same as P2V, but without casts

#endif // _MEM_LAYOUT_H_
