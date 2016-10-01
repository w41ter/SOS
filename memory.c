#include "bitmap.h"
#include "console.h"
#include "debug.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "types.h"
#include "vm.h"

struct pool {
    bitmap bitmap;
    uint32_t phy_addr_start;
    uint32_t size;
};

struct pool kernel_pool, user_pool;
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
    uint16_t kernel_free_pages = all_free_pages >> 1;
    uint16_t user_free_pages = all_free_pages - kernel_free_pages;
    uint32_t kbm_length = kernel_free_pages >> 3;
    uint32_t ubm_length = user_free_pages >> 3;
    uint32_t kp_start = (uint32_t)V2P(KERNEL_HEAP_START);
    uint32_t up_start = kp_start + kernel_free_pages * PAGE_SIZE;

    kernel_pool.phy_addr_start = kp_start;
    kernel_pool.size = kernel_free_pages * PAGE_SIZE;
    kernel_pool.bitmap.btmp_bytes_len = kbm_length;
    kernel_pool.bitmap.bits = (uint8_t*)MEM_BITMAP_BASE;

    user_pool.phy_addr_start = up_start;
    user_pool.size = user_free_pages * PAGE_SIZE;
    user_pool.bitmap.btmp_bytes_len = ubm_length;
    user_pool.bitmap.bits = (uint8_t*)(MEM_BITMAP_BASE + kbm_length);

    bitmap_init(&kernel_pool.bitmap);
    bitmap_init(&user_pool.bitmap);

    kvm.bitmap.btmp_bytes_len = kbm_length;
    kvm.bitmap.bits = 
        (uint8_t*)(MEM_BITMAP_BASE + kbm_length + ubm_length);
    kvm.start = KERNEL_HEAP_START;
    bitmap_init(&kvm.bitmap);

    printk("kernel physic mem address:0x%08x size:0x%08x\n", 
        kernel_pool.bitmap.bits, kernel_pool.bitmap.btmp_bytes_len);
    printk("user physic mem address:0x%08x size:0x%08x\n", 
        user_pool.bitmap.bits, user_pool.bitmap.btmp_bytes_len);
}

uint32_t alloc_kernel_ppages(uint32_t n)
{
    // printk("try to allocate physic page: %d\n", n);
    uint32_t total = 0, start_addr;
    uint32_t bit_idx_start = bitmap_scan(&kernel_pool.bitmap, n);
    if (bit_idx_start == -1)
        return 0;
    for (; total < n; ++total) {
        bitmap_set(&kernel_pool.bitmap, bit_idx_start + total, 1);
    }
    start_addr = kernel_pool.phy_addr_start + bit_idx_start * PAGE_SIZE;
    return start_addr;
}

void pmm_init(void)
{
    memory_pool_init(find_max_pa());
}
