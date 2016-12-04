#pragma once

#include <libs/types.h>

typedef struct SpinLock {
    uint32_t locked;
    // for debug
    const char *name;
} SpinLock;

void InitSpinLock(SpinLock *lock, const char *name);
void Acquire(SpinLock *lock);
void Release(SpinLock *lock);

void PushClearInterupt(void);
void PopClearInterupt(void);