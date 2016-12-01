#include <x86.h>
#include <param.h>
#include <mm/segment.h>
#include <libs/list.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <proc/proc.h>
#include <proc/schedule.h>

extern void ProcessSwitchTo(ProcessContext *from, ProcessContext *to);

extern struct list_t ProcessList; // proc.c

static void RunPorcess(ProcessControlBlock *next)
{
    assert(next && "nullptr exception");

    ProcessControlBlock *current = GetCurrentProcess();

    next->state = PS_Running;
    SetCurrentProcess(next);
    LoadESP0((uint32_t)next->kstack + KSTACKSIZE);
    ProcessSwitchTo(&current->context, &next->context);
}

void Schedule(void)
{
    //cli();
    ProcessControlBlock *p = NULL, *next = NULL;
    list_for_each(node, &ProcessList) {
        p = GET_PCB_FROM_LIST_NODE(node);
        if (p->state == PS_Ready) {
            if (next == NULL || (next->counter < p->counter)) {
                /* if first process or has less priority */
                next = p;
            } 
        }
        p->counter = (p->counter >> 1) + p->priority;
    }

    assert(next && "logic error");
    printk("--=== current process pid is: %d\n", next->pid);
    RunPorcess(next);
    //sti();
}

void OnTimer(void)
{
    ProcessYield();
}