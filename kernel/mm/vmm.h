#ifndef _VM_H_
#define _VM_H_

#include <libs/list.h>
#include <libs/types.h>
#include <trap/traps.h>

/* kmalloc&kfree */
#include <mm/slab.h>

/* paging */
#include <mm/paging.h>

typedef struct MemoryArea {
    uint32_t start;
    uint32_t end;
    uint32_t flags;
    struct list_node_t node;
} MemoryArea;

typedef struct MemoryLayout {
    MemoryArea *cache;  // current visit area, used for speed purpose.
    PageDirectoryEntity *pgdir;
    struct list_t list;
} MemoryLayout;

#define GET_MEMORY_AREA_FROM_LIST_NODE(ptr) (list_get(ptr, MemoryArea, node))

void SetupVirtualMemoryManager(void);
void InitUserVM(PageDirectoryEntity *pgdir, void *start, size_t size);

/* virtual memory */
MemoryLayout * MemoryLayoutCreate(void);
void DestroyMemoryLayout(MemoryLayout *mm);

MemoryArea * MemoryAreaCreate(uint32_t start, uint32_t end, uint32_t flags);
void DestroyMemoryArea(MemoryArea *ma);

MemoryArea * FindMemoryArea(MemoryLayout *mm, uintptr_t address);
void InsertMemoryArea(MemoryLayout *mm, MemoryArea *ma);

int MemoryMap(MemoryLayout *mm, uintptr_t addr, size_t len, uint32_t flags);
int CopyMemoryMap(MemoryLayout *from, MemoryLayout *to);
void ExitMemoryMap(MemoryLayout *mm);

#endif 