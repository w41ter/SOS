#ifndef _VM_H_
#define _VM_H_

#include "libs/list.h"
#include "types.h"

// A virtual address 'la' has a three-part structure as follows:
//
// +--------10------+-------10-------+---------12----------+
// | Page Directory |   Page Table   | Offset within Page  |
// |      Index     |      Index     |                     |
// +----------------+----------------+---------------------+
//  \--- PDX(va) --/ \--- PTX(va) --/

// page directory index
#define PDX(va)         (((uint32_t)(va) >> PDX_SHIFT) & 0x3FF)

// page table index
#define PTX(va)         (((uint32_t)(va) >> PTX_SHIFT) & 0x3FF)

// construct virtual address from indexes and offset
#define PGADDR(d, t, o) ((uint32_t)((d) << PDX_SHIFT | (t) << PTX_SHIFT | (o)))

// Page directory and page table constants.
#define NPDENTRIES      1024    // # directory entries per page directory
#define NPTENTRIES      1024    // # PTEs per page table
#define PAGE_SIZE       4096    // bytes mapped by a page

#define PG_SHIFT         12      // log2(PG_SHIFT)
#define PTX_SHIFT        12      // offset of PTX in a linear address
#define PDX_SHIFT        22      // offset of PDX in a linear address

#define PGROUNDUP(sz)  ((int)((sz)+PAGE_SIZE-1) & ~(PAGE_SIZE-1))
#define PGROUNDDOWN(a) (((a)) & ~(PAGE_SIZE-1))

// Page table/directory entry flags.
#define PTE_P           0x001   // Present
#define PTE_W           0x002   // Writeable
#define PTE_U           0x004   // User
#define PTE_PWT         0x008   // Write-Through
#define PTE_PCD         0x010   // Cache-Disable
#define PTE_A           0x020   // Accessed
#define PTE_D           0x040   // Dirty
#define PTE_PS          0x080   // Page Size
#define PTE_MBZ         0x180   // Bits must be zero

// Address in page table or page directory entry
#define PTE_ADDR(pte)   ((uint32_t)(pte) & ~0xFFF)
#define PTE_FLAGS(pte)  ((uint32_t)(pte) &  0xFFF)


// 页目录数据类型
typedef uint32_t pde_t;

// 页表数据类型
typedef uint32_t pte_t;

// 映射 512MB 内存所需要的页表数
#define PTE_COUNT 128

// 页掩码，用于 4KB 对齐
#define PAGE_MASK      0xFFFFF000

#endif 