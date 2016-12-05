# Initial process execs /init.
# This code runs in user space.

#include <trap/traps.h>

.globl start
start:
    movl $2, %eax   #fork
    int $(T_SYSCALL)
loop:
    nop
    nop
    nop
    jmp loop
