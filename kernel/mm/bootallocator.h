#pragma once

#include <libs/types.h>

void SetupBootAllocator(uint32_t free);
void * BootAllocPages(size_t npage);
void * BootAllocPage(void);
void BootExtendMemoryTo(uint32_t last);
uint32_t GetBootAllocatorFreeAddress(void);