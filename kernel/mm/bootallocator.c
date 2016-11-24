#include <vm.h>
#include <mm/memlayout.h>
#include <mm/bootallocator.h>

struct BootAllocator {
    uint32_t start;
    uint32_t free;
} bootAllocator;

typedef uint32_t PageDirectoryEntry;

extern PageDirectoryEntry entrypgdir[];

void BootAllocatorInitialize(uint32_t free) 
{
    bootAllocator.start = PGROUNDUP(free);
    bootAllocator.free = bootAllocator.start;
}

void BootExtendMemoryTo(uint32_t last)
{
    int from = bootAllocator.free >> PDX_SHIFT;
    int end = last >> PDX_SHIFT;
    for (from++; from <= end; from++) {
        entrypgdir[from] = V2P(from << PDX_SHIFT) | PTE_P | PTE_W | PTE_PS;
    }
}

void * BootAllocPages(size_t npage)
{
    uint32_t end = PGROUNDUP(BootAllocator.free) + PAGE_SIZE;
    BootExtendMemoryTo(end);
    return (void*)end;
}

void * BootAllocPage(void)
{
    return BootAllocPages(1);
}
