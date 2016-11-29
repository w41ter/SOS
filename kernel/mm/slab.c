#include <mm/vmm.h>
#include <mm/pmm.h>
#include <mm/slab.h>
#include <libs/list.h>
#include <libs/stdio.h>
#include <libs/debug.h>

#define VIRTUAL_ADDRESS_TO_SLAB_PAGE(ptr) \
    ((void *)(((uint32_t)ptr) & PAGE_MASK))

#define GET_SLAB_PAGE_FROM_LIST_NODE(item) \
    (list_get(item, SlabPage, node))

typedef struct SlabPage {             
    size_t avail;/* Available objects */
    size_t limit;/* Max objects in current SlabPage */
    char *objectBase;/* Base address of object array */

    struct Cache *cache;/* Owner kmem_cache */
    struct list_node_t node;
    void *free[0];/* Free object pointer array in this
                                       slab_page, this array is dynamic
                                       allocated, array size is limit. */
} SlabPage;

typedef struct Cache {
    size_t objectSize;/* Object raw size */
    size_t size;/* Aligned object size */
    size_t align;/* Align size */

    struct list_t full;
    struct list_t partial;
    struct list_t free;
} Cache;

#define CACHE_CHAIN_SIZE    9
Cache CacheChain[9];

static void SlabPageInitialize(SlabPage *page)
{
    assert(page && "nullptr exception");
    page->avail = 0;
    page->limit = 0;
    page->objectBase = NULL;
    page->cache = NULL;
    //page->free = NULL;
    list_node_init(&page->node);
}

static void CacheInitialize(Cache *cache, size_t size) 
{
    assert(cache && "nullptr exception.");
    cache->objectSize = size;
    cache->size = size;
    cache->align = sizeof(void*);

    list_init(&cache->free);
    list_init(&cache->partial);
    list_init(&cache->full);
}

static void CacheChainInitialize(void) 
{
    for (size_t i = 0; i < CACHE_CHAIN_SIZE; ++i) {
        CacheInitialize(&CacheChain[i], 1 << (i+2));
    }
}

static void CacheInsertSlabPage(Cache *cache, SlabPage *slab) 
{
    assert(cache && "null ptr exception");

    SlabPageInitialize(slab);

    size_t payload = PAGE_SIZE - sizeof(*slab);

    /* Calculate capacity */
    slab->limit = payload / cache->size;
    slab->objectBase = (char *)slab + (PAGE_SIZE - (slab->limit * cache->size));
    slab->cache = cache;
    slab->avail = 0;

    /* Store all available objects address */
    for (size_t i = 0; i < slab->limit; ++i)
        slab->free[slab->avail++] = slab->objectBase + i * cache->size;

    /* Insert into free list */
    list_prepend(&cache->free, &slab->node);
}

static SlabPage * ExtendSlabPage(Cache *cache) 
{
    Page *page = PhysicAllocatePage();
    if (!page)
        panic("[slab] - alloc a physical page failed.");

    SlabPage *slab = PageToVirtualAddress(page);
    CacheInsertSlabPage(cache, slab);
    return slab;
}

static void * AllocateObjectFromSlabPage(SlabPage * slab) 
{
    void *object = NULL;
    if (slab->avail == 0)
        panic("[slab] - Fatal error, alloc object from full slab.");

    object = slab->free[--slab->avail];

    if (slab->avail == 0) {
        /* Move from partial slab list into full slab list. */
        list_remove(&slab->node);
        list_append(&slab->cache->full, &slab->node);
    }
    else if (slab->avail + 1 == slab->limit) {
        /* Move from free slab list into partial slab list. */
        list_remove(&slab->node);
        list_append(&slab->cache->partial, &slab->node);
    }

    return object;
}

static void * AllocateObjectFromSlabList(struct list_t *slab)
{
    assert(slab && "null ptr exception");

    if (list_empty(slab)) 
        return NULL;
    return AllocateObjectFromSlabPage(
        GET_SLAB_PAGE_FROM_LIST_NODE(list_head(slab)));
}

static void * AllocateObject(Cache *cache) 
{
    assert(cache && "null ptr exception.");
    void *object = NULL;

    /* Alloc from partial slab first, free slab secondly */
    object = AllocateObjectFromSlabList(&cache->partial);
    if (!object) {
        object = AllocateObjectFromSlabList(&cache->free);
    }

    if (!object) {
        /*
         * No available object in free or partial slab list,
         * then we alloc a new slab.
         */
        SlabPage *page = ExtendSlabPage(cache);
        object = AllocateObjectFromSlabPage(page);
        if (!object) {
            panic("[slab] - Fatal error, alloc object fail from a new slab.");
        }
    }

    return object;
}

static void FreeObject(void *object) 
{
    assert(object && "null exception");

    SlabPage *slab = VIRTUAL_ADDRESS_TO_SLAB_PAGE(object);
    if (!slab)
        panic("[slab] - Fatal error, slab is nullptr.");

    Cache *cache = slab->cache;
    
    // TODO: check object is correct.
    slab->free[slab->avail++] = object;

    if (slab->avail == 1 && slab->avail < slab->limit) {
        /* Move from full slab list into partial slab list. */
        list_remove(&slab->node);
        list_append(&cache->partial, &slab->node);
    }
    else if (slab->avail == slab->limit) {
        /* Move from partial slab list into free slab list. */
        list_remove(&slab->node);
        list_append(&cache->free, &slab->node);
    }
}

static Cache * GetObjectCache(size_t size)
{
    if (size <= 4) size = 0;
    else if (size <= 8) size = 1;
    else if (size <= 16) size = 2;
    else if (size <= 32) size = 3;
    else if (size <= 64) size = 4;
    else if (size <= 128) size = 5;
    else if (size <= 256) size = 6;
    else if (size <= 512) size = 7;
    else if (size <= 1024) size = 8;
    else panic("[BUG] kmalloc: can not alloc memory for more than 1024.");
    return CacheChain + size;
}

void SlabSetup(void)
{
    printk(" [+] setup slab allocator\n");
    CacheChainInitialize();
}

void * kmalloc(size_t size)
{
    Cache *cache = GetObjectCache(size);
    return AllocateObject(cache);
}

void kfree(void *ptr)
{
    FreeObject(ptr);
}