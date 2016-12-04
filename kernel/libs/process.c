#include <libs/unistd.h>
#include <libs/stdio.h>
#include <syscall/syscall.h>
#include <libs/debug.h>

int fork(void)
{
    return SystemCall(SYS_fork);
}

int exit(int exit_code) 
{
    return SystemCall(SYS_exit, exit_code);
}

int getpid(void)
{
    return SystemCall(SYS_getpid);
}