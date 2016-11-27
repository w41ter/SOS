#pragma once

#include <libs/types.h>

void SlabSetup(void);
void * kmalloc(size_t size);
void kfree(void *ptr);