#pragma once

#include <libs/types.h>
#include <libs/list.h>

typedef struct Page {
    int ref;
    uint32_t flags;
    uint32_t property;
    struct list_node_t node;
} Page;

/* Flags describing the status of a page frame */
enum { 
    PG_Reserved = 0,
    PG_Free = 1,
};

void PhysicMemoryInitialize(void);
uint32_t SizeOfFreePhysicPage();
Page* PhysicAllocatePages(size_t n);
void PhysicFreePages(Page *base, size_t n);