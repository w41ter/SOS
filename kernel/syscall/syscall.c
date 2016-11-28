#include <libs/debug.h>
#include <libs/stdio.h>
#include <trap/traps.h>

void SystemCall(void) {
    printk("undefined syscall\n");
}

