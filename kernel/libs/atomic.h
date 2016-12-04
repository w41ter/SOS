#pragma once

#include <libs/types.h>

struct atomic_t {
    volatile int count;
};

#define ATOMIC_INIT(n) { (n) }

static inline int atomic_read(const struct atomic_t *v)
{
    return v->count;
}

static inline void atomic_set(struct atomic_t *v, int i)
{
	v->count = i;
}

static inline void atomic_add(int i, struct atomic_t *v)
{
	asm volatile("addl %1,%0"
		     : "+m" (v->count)
		     : "ir" (i));
}

static inline void atomic_sub(int i, struct atomic_t *v)
{
	asm volatile("subl %1,%0"
		     : "+m" (v->count)
		     : "ir" (i));
}

static inline int atomic_sub_and_test(int i, struct atomic_t *v)
{
	unsigned char c;

	asm volatile("subl %2,%0; sete %1"
		     : "+m" (v->count), "=qm" (c)
		     : "ir" (i) : "memory");
	return c;
}

static inline void atomic_inc(struct atomic_t *v)
{
	asm volatile("incl %0"
		     : "+m" (v->count));
}

static inline void atomic_dec(struct atomic_t *v)
{
	asm volatile("decl %0"
		     : "+m" (v->count));
}

static inline int atomic_dec_and_test(struct atomic_t *v)
{
	unsigned char c;

	asm volatile("decl %0; sete %1"
		     : "+m" (v->count), "=qm" (c)
		     : : "memory");
	return c != 0;
}

static inline int atomic_inc_and_test(struct atomic_t *v)
{
	unsigned char c;

	asm volatile("incl %0; sete %1"
		     : "+m" (v->count), "=qm" (c)
		     : : "memory");
	return c != 0;
}

static inline int atomic_inc_return(struct atomic_t *v)
{
	asm volatile("incl %0"
		     : "+m" (v->count));
    return v->count;
}

static inline int atomic_dec_return(struct atomic_t *v)
{
	asm volatile("decl %0"
		     : "+m" (v->count));
    return v->count;
}
