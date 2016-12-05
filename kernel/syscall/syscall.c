#include <libs/types.h>
#include <libs/debug.h>
#include <libs/stdio.h>
#include <libs/unistd.h>
#include <libs/vsprintf.h>
#include <trap/traps.h>
#include <proc/proc.h>

static int
sys_exit(uint32_t arg[]) 
{
    int error_code = (int)arg[0];
    ProcessExit(error_code);
    return 0;
}

static int
sys_fork(uint32_t arg[]) 
{
    return ProcessFork();
}

static int
sys_getpid(uint32_t arg[]) 
{
    return ProcessGetPID();
}

static int (*syscalls[])(uint32_t arg[]) = {
    [SYS_exit]              sys_exit,
    [SYS_fork]              sys_fork,
    [SYS_getpid]            sys_getpid,
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void SolveSystemCall(TrapFrame *tf) 
{
    // Ensure current trap frame always correct.
    ProcessControlBlock *current = GetCurrentProcess();
    current->tf = tf;
    int num = tf->eax;
    if (num >= 0 && num < NUM_SYSCALLS) {
        if (syscalls[num] != NULL) {
            uint32_t arg[5];
            arg[0] = tf->edx;
            arg[1] = tf->ecx;
            arg[2] = tf->ebx;
            arg[3] = tf->edi;
            arg[4] = tf->esi;
            tf->eax = syscalls[num](arg);
            return ;
        }
    }
    PrintTrapFrame(tf);
    printk("no:%d current process %d name %s\n", 
        num, current->pid, current->name);
    panic("undefined syscall\n");
}

#define MAX_ARGS 5

int SystemCall(int num, ...) 
{
    va_list ap;
    va_start(ap, num);
    uint32_t a[MAX_ARGS];
    for (int i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint32_t);
    }
    va_end(ap);

    int ret;
    asm volatile (
        "int %1;"
        : "=a" (ret)
        : "i" (T_SYSCALL),
          "a" (num),
          "d" (a[0]),
          "c" (a[1]),
          "b" (a[2]),
          "D" (a[3]),
          "S" (a[4])
        : "cc", "memory");

    return ret;
}