#include <x86.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <proc/spinlock.h>

static size_t numberOfClearInterupt = 1;    // default is 1, because first time into kernel is disable interupt.

void InitSpinLock(SpinLock *lock, const char *name)
{
    assert(lock && name && "nullptr exception");

    lock->locked = 0;
    lock->name = name;
}

void Acquire(SpinLock *lock)
{
    assert(lock && "nullptr exception");
    PushClearInterupt();
    /* if locked by others, wait */
    while (xchg(&lock->locked, 1) == 0)
        ;
}

void Release(SpinLock *lock)
{
    assert(lock && "nullptr exception");
    lock->locked = 0;    
    PopClearInterupt();
}

// Pushcli/popcli are like cli/sti except that they are matched:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void PushClearInterupt(void)
{
    cli();
    numberOfClearInterupt++;
}

void PopClearInterupt(void)
{
    if (readeflags() & FL_IF)
        panic("popcli - interruptible");
    if (--numberOfClearInterupt < 0)
        panic("popcli");
    if (numberOfClearInterupt == 0) 
        sti();
}
