#pragma once

#include <libs/types.h>

void BootAllocatorInitialize(uint32_t free);
//void * BootAllocPages(size_t npage);
void BootExtendMemoryTo(uint32_t last);