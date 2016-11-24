#pragma once

#include <libs/types.h>

void IDEInitialize(void);
bool IsIDEDeviceValid(uint16_t ideno);
size_t IDEDeviceSize(uint16_t ideno);

int IDEReadSectors(uint16_t ideno, uint32_t sectorno, void *dest, size_t nsecs);
int IDEWriteSectors(uint16_t ideno, uint32_t sectorno, const void *src, size_t nsecs);
