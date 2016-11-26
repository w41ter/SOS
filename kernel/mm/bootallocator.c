#include <mm/vmm.h>
#include <mm/memlayout.h>
#include <mm/bootallocator.h>
#include <libs/stdio.h>
#include <libs/debug.h>

struct BootAllocator {
    uint32_t start;
    uint32_t free;
} bootAllocator;

extern PageDirectoryEntity entrypgdir[];

/** 
 * NOTICE: free 是物理地址
 */
void BootAllocatorSetup(uint32_t free) 
{
    assert(free < KERNEL_BASE && "Free address must be physic.");
    printk(" [+] setup boot allocator at 0x%08x\n", free);
    bootAllocator.start = PGROUNDUP(free);
    bootAllocator.free = bootAllocator.start;
}

/**
 * last 表示第一个空闲空间地址
 */
void BootExtendMemoryTo(uint32_t last)
{
    assert(last < KERNEL_BASE && "Last address must be physic");
    assert(bootAllocator.free < last && "can't extend memory range.");

    int from = (uint32_t)P2V(bootAllocator.free) >> PDX_SHIFT;
    int end = (uint32_t)P2V(last) >> PDX_SHIFT;
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

uint32_t GetBootAllocatorFreeAddress(void)
{
    return bootAllocator.free;
}
