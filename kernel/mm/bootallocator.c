#include <mm/vmm.h>
#include <mm/memlayout.h>
#include <mm/bootallocator.h>

struct BootAllocator {
    uint32_t start;
    uint32_t free;
} bootAllocator;

extern PageDirectoryEntity entrypgdir[];

/** 
 * NOTICE: free 是物理地址
 */
void BootAllocatorInitialize(uint32_t free) 
{
    bootAllocator.start = PGROUNDUP(free);
    bootAllocator.free = bootAllocator.start;
}

/**
 * last 表示第一个空闲空间地址
 */
void BootExtendMemoryTo(uint32_t last)
{
    int from = bootAllocator.free >> PDX_SHIFT;
    int end = last >> PDX_SHIFT;
    for (from++; from <= end; from++) {
        entrypgdir[from] = (from << PDX_SHIFT) | PTE_P | PTE_W | PTE_PS;
    }
    bootAllocator.free = last;
}

void * BootAllocPages(size_t npage)
{
    uint32_t end = PGROUNDUP(bootAllocator.free) + PAGE_SIZE;
    BootExtendMemoryTo(end);
    return (void*)end;
}

void * BootAllocPage(void)
{
    return BootAllocPages(1);
}
