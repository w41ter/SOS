#include "bitmap.h"
#include "console.h"
#include "debug.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "types.h"
#include "spinlock.h"
#include "vm.h"

struct pool {
    bitmap bitmap;
    uint32_t phy_addr_start;
    uint32_t size;
    struct spinlock lock;
};

struct pool pmm;
extern struct virtual_addr kvm;     // define at vm.c

// some constants for bios interrupt 15h AX = 0xE820
#define E820MAX             20      // number of entries in E820MAP
#define E820_ARM            1       // address range memory
#define E820_ARR            2       // address range reserved

struct e820map {
    int nr_map;
    struct {
        uint64_t addr;
        uint64_t size;
        uint32_t type;
    } __attribute__((packed)) map[E820MAX];
};

static uint64_t find_max_pa(void) 
{
    struct e820map *memmap = (struct e820map*)(0x8000 + KERNEL_BASE);
    uint64_t maxpa = 0;

    printk("e820map:\n");
    int i;
    for (i = 0; i < memmap->nr_map; i ++) {
        uint64_t begin = memmap->map[i].addr, 
            end = begin + memmap->map[i].size;
        printk("  memory: 0x%08x, [0x%08x, 0x%08x], type = %d.\n",
                memmap->map[i].size, begin, end - 1, memmap->map[i].type);
        if (memmap->map[i].type == E820_ARM) {
            if (maxpa < end) {
                maxpa = end;
            }
        }
    }
    return maxpa;
}

static void memory_pool_init(uint32_t all_mem)
{
    assert(all_mem > 0);
    
    uint32_t free_mem = all_mem - (uint32_t)V2P(KERNEL_HEAP_START);
    uint16_t all_free_pages = free_mem / PAGE_SIZE;
    uint32_t kbm_length = all_free_pages >> 3;

    pmm.phy_addr_start = (uint32_t)V2P(KERNEL_HEAP_START);
    pmm.size = all_free_pages * PAGE_SIZE;
    pmm.bitmap.btmp_bytes_len = kbm_length;
    pmm.bitmap.bits = (uint8_t*)MEM_BITMAP_BASE;

    bitmap_init(&pmm.bitmap);

    printk("physic mem address:0x%08x size:0x%08x\n", 
        pmm.bitmap.bits, pmm.bitmap.btmp_bytes_len);

    all_free_pages = (DEVSPACE-KERNEL_HEAP_START) / PAGE_SIZE; 
    kvm.bitmap.btmp_bytes_len = all_free_pages >> 3;
    kvm.bitmap.bits = (uint8_t*)(MEM_BITMAP_BASE + kbm_length);
    kvm.start = KERNEL_HEAP_START;
    bitmap_init(&kvm.bitmap);
}

uint32_t alloc_physic_pages(uint32_t n)
{
    // printk("try to allocate physic page: %d\n", n);
    acquire(&pmm.lock);
    uint32_t total = 0, start_addr;
    uint32_t bit_idx_start = bitmap_scan(&pmm.bitmap, n);
    if (bit_idx_start == -1) {
        release(&pmm.lock);
        return 0;
    }
    for (; total < n; ++total) {
        bitmap_set(&pmm.bitmap, bit_idx_start + total, 1);
    }
    start_addr = pmm.phy_addr_start + bit_idx_start * PAGE_SIZE;
    release(&pmm.lock);
    return start_addr;
}

void free_physic_pages(uint32_t pa, uint32_t size)
{
    uint32_t bit_idx = (pa-pmm.phy_addr_start) / PAGE_SIZE;
    acquire(&pmm.lock);
    while (size--) {
        bitmap_set(&pmm.bitmap, bit_idx++, 0);
    }
    release(&pmm.lock);
}

void pmm_init(void)
{
    memory_pool_init(find_max_pa());

    init_lock(&pmm.lock, "pmm");
}
