#include <mm/vmm.h>
#include <mm/pmm.h>
#include <mm/segment.h>
#include <mm/bootallocator.h>
#include <mm/memlayout.h>
#include <libs/stdio.h>
#include <libs/debug.h>

#define GET_PAGE_FROM_LIST_NODE(ptr) (list_get((ptr), struct Page, node))

typedef struct FreePhysicArea {
    struct list_t list;
    uint32_t freeNumbers;
} FreePhysicArea;

FreePhysicArea freeArea;

/* WARNING: no change it */
Page *pages;

static void FreeAreaInitialize(FreePhysicArea *freeArea) 
{
    assert(freeArea && "null ptr exception.");

    list_init(&freeArea->list);
    freeArea->freeNumbers = 0;
}

static void PageInitialize(Page *page) 
{
    assert(page && "null ptr exception");

    /* default property is  PG_Reserved */
    page->ref = 0;
    page->flags = PG_Reserved;
    page->property = 0;
    list_node_init(&page->node);
}

static void SetPageReserved(Page *page)
{
    assert(page && "null ptr exception.");

    page->flags = PG_Reserved;
}

/**
 * free physic page and insert into free area 
 */
static void SetPageFree(Page *page)
{
    assert(page && "null ptr exception");

    page->flags = PG_Free;
}

static bool IsPageReserved(Page *page) 
{
    assert(page && "null ptr exception.");

    return page->flags == PG_Reserved;
}

static void ClearPageRef(Page *page) 
{
    assert(page && "null ptr exception.");
    page->ref = 0;
}

// static void IncreatePageRef(Page *page) 
// {
//     assert(page && "null ptr exception.");
//     page->ref++;
// }

// static void DecreatePageRef(Page *page)
// {
//     assert(page && "null ptr exception.");
//     page->ref--;
//     assert(page->ref >= 0 && "decrease the number of unused page.");
// }

static void FreePhysicMemoryInitialize(uint32_t *base, uint32_t size)
{
    assert(base && pages && "nullptr exception");

    printk("  [+] total page: %d\n", size);

    Page *page = pages + (uint32_t)base / PAGE_SIZE;
    freeArea.freeNumbers = size;
    /* first block */
    page->property = size;
    while (size--) {
        assert(((uint32_t)page < (uint32_t)P2V(base)) 
            && "out of memory range.");

        SetPageFree(page);
        list_append(&freeArea.list, &page->node);
        page++;
    }

    // test
    page = GET_PAGE_FROM_LIST_NODE(list_head(&freeArea.list));
    assert(page && page->property == freeArea.freeNumbers
        && "init free area space error");
}

static void PMMPageInitialize(uint32_t kernelEnd)
{
    uint32_t nPages = GetPhysicMemorySize() / PAGE_SIZE;

    pages = (Page*)PGROUNDUP(kernelEnd);
    uint32_t freeMemoryBeginAt = V2P(pages + nPages);

    /* ensure no page fault. */
    BootExtendMemoryTo(freeMemoryBeginAt);

    printk(" [+] initialize physic pages\n");
    printk("  [+] total pages is: 0x%08x\n", nPages);
    printk("  [+] pages virtual begin at: 0x%08x\n", pages);

    FreeAreaInitialize(&freeArea);
    for (int i = 0; i < nPages; ++i) {
        PageInitialize(pages + i);
    }
}

static void PMMZoneInitialize(void) 
{
    uint32_t freeMemoryBeginAt = GetBootAllocatorFreeAddress();
    uint32_t lowMemoryTop = GetLowMemoryTop();
    printk(" [+] free memory begin at: 0x%08x\n", freeMemoryBeginAt);

    FreePhysicMemoryInitialize((uint32_t*)PGROUNDUP(freeMemoryBeginAt),
        (lowMemoryTop - freeMemoryBeginAt) / PAGE_SIZE);
}

static void PMMAllocatorSetup(void)
{
    SlabSetup();
}

void PMMInitialize(void)
{
    extern char end[];
    uint32_t kernelEnd = V2P(PGROUNDUP((void*)end));
    
    printk("++ setup physic memory manager\n");
    printk(" [+] kernel load end at: 0x%08x\n", V2P(end));

    FindLowMemoryTop();
    /* for memory map */
    BootAllocatorSetup(kernelEnd);
    PMMPageInitialize((uint32_t)end);
    PagingInitialize();
    GDTInitialize();
    PMMZoneInitialize();
    PMMAllocatorSetup();
}

uint32_t SizeOfFreePhysicPage()
{
    return freeArea.freeNumbers;
}

/**
 * allocate & return Pages.
 */
Page* PhysicAllocatePages(size_t n)
{
    assert(n > 0 && "can not allocate zero pages.");

    if (n > SizeOfFreePhysicPage())
        return NULL;

    assert(list_size(&freeArea.list) != 0);
    list_for_each(node, &freeArea.list) {
        Page *p = GET_PAGE_FROM_LIST_NODE(node);
        assert(p && "PhysicAllocatePages: error occupied when iterate freeArea.list.");
        assert(p->property != 0 && "logic error");

        if (p->property >= n) {
            int32_t leave = p->property - n;
            /* find! */
            for (int i = 0; i < n; ++i) {
                assert(node && "PhysicAllocatePages: error occupied");
                struct list_node_t *tmp = node;
                node = list_node_next(node);
                list_remove(tmp);
                
                Page *tp = GET_PAGE_FROM_LIST_NODE(tmp);
                ClearPageRef(tp);
                SetPageReserved(tp);
                tp->property = 0;
            }
            if (leave > 0) {
                /* current node point to next block */
                assert(node && "PhysicAllocatePages: error occupied");
                Page *tp = GET_PAGE_FROM_LIST_NODE(node);

                assert(pages <= tp 
                    && (uint32_t)tp < (uint32_t)P2V(GetLowMemoryTop())
                    && "please no free memory out of range.");
                
                tp->property = leave;
            }   
            freeArea.freeNumbers -= n;
            return p;
        }
        else {
            /* we can skip nodes easily because 
               pages block are adjust in physic */
            Page *lastPage = p + p->property - 1;
            node = &lastPage->node;
        }
    }

    /* can't find proper block when progress visit here. */
    return NULL;
}

void PhysicFreePages(Page *base, size_t n)
{
    assert(pages <= base 
        && (uint32_t)base < (uint32_t)P2V(GetLowMemoryTop())
        && "please no free memory out of range.");
    assert(n > 0 && "can not free zero page");
    assert(IsPageReserved(base) && "try to release unused memory.");

    Page *p = NULL;
    list_for_each(node, &freeArea.list) {
        p = GET_PAGE_FROM_LIST_NODE(node);
        if (p > base)
            break;
    }

    for (Page *t = base; t < base + n; t++) {
        list_insert(&p->node, &t->node);
        SetPageFree(t);
        ClearPageRef(t);
    }
    base->property = n;
    
    /* merge lst block */
    if (base + n == p) {
        base->property += p->property;
        p->property = 0;
    }

    /* merge fst block */
    struct list_node_t *prev = list_node_prev(&base->node);
    p = GET_PAGE_FROM_LIST_NODE(prev);
    if (prev != list_end() && p == base - 1) {
        while (prev != list_end()) {
            if (p->property) {
                p->property += base->property;
                base->property = 0;
                break;
            }
            prev = list_node_prev(prev);
            p = GET_PAGE_FROM_LIST_NODE(prev);
        }
    }

    freeArea.freeNumbers += n;
}

Page * PhysicAllocatePage()
{
    return PhysicAllocatePages(1);
}

void PhysicFreePage(Page *page) 
{
    return PhysicFreePages(page, 1);
}

void * PageToVirtualAddress(Page *page) 
{
    assert(pages <= page 
        && (uint32_t)page < (uint32_t)P2V(GetLowMemoryTop())
        && "page out of range.");
    assert(((uint32_t)page & ~PAGE_MASK) && "invaild page address");
    
    size_t pageIndex = page - pages;
    return P2V(pageIndex * PAGE_SIZE);
}

Page * VirtualAddressToPage(void *address)
{
    uint32_t phy = V2P(address);
    if (phy > GetLowMemoryTop()) {
        panic("VirtualAddressToPage called with invalid pa");
    }
    return &pages[phy >> 12];
}
