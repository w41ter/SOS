#ifndef _SYSCALL_H_
#define _SYSCALL_H_

#include "types.h"

enum {
    _NR_getpid,
    _NR_write,
};

int fetchint(uint32_t addr, int *ip);
int fetchstr(uint32_t addr, char **pp);
int argint(int n, int *ip);
int argptr(int n, char **pp, int size);
int argstr(int n, char **pp);
void syscall(void);

#endif 