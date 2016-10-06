#ifndef _SPIN_LOCK_H_
#define _SPIN_LOCK_H_

#include "types.h"

// Mutual exclusion lock.
struct spinlock {
  uint32_t locked;       // Is the lock held?

  // For debugging:
  const char *name;        // Name of lock.
  struct cpu *cpu;   // The cpu holding the lock.
  uint32_t pcs[10];      // The call stack (an array of program counters)
                     // that locked the lock.
};

void init_lock(struct spinlock *lk, const char *name);
void push_cli(void);
void pop_cli(void);
int holding(struct spinlock *lock);
void get_caller_pcs(void *v, uint32_t pcs[]);
void acquire(struct spinlock *lk);
void release(struct spinlock *lk);

#endif