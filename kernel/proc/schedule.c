#include <x86.h>
#include <param.h>
#include <mm/mm.h>
#include <libs/list.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <proc/proc.h>
#include <proc/schedule.h>

extern void ProcessSwitchTo(ProcessContext *from, ProcessContext *to);

extern struct list_t ProcessList; // proc.c

static void SwitchVM(ProcessControlBlock *next)
{
    LoadPageDirectory(next->pid == 0 /* idle */
        ? GetBootPageDirectory() : next->mm->pgdir);
}

static void RunPorcess(ProcessControlBlock *next)
{
    assert(next && "nullptr exception");

    ProcessControlBlock *current = GetCurrentProcess();
    
    next->counter --;
    next->state = PS_Running;
    SetCurrentProcess(next);
    SwitchVM(next);
    LoadESP0((uint32_t)next->kstack + KSTACKSIZE);
    ProcessSwitchTo(&current->context, &next->context);
}

void Schedule(void)
{
    cli();
    ProcessControlBlock *p = NULL, *next = NULL;
    for (;;) {
        p = NULL;
        next = NULL;
        int counter = -1;
        list_for_each(node, &ProcessList) {
            p = GET_PCB_FROM_LIST_NODE(node);
            if (p->state == PS_Ready && counter < p->counter) {
                /* if first process or has less counter */
                next = p; 
                counter = p->counter;
            }
        }

        if (next)   
            break;

        list_for_each(node, &ProcessList) {
            p = GET_PCB_FROM_LIST_NODE(node);
            p->counter = (p->counter >> 1) + p->priority;
        }
    }

    assert(next && "logic error");
    RunPorcess(next);
    ProcessControlBlock *current = GetCurrentProcess();
    sti();
}

void OnTimer(void)
{
    ProcessYield();
}

void SetupScheduleManager(void)
{
    printk("++ setup schedule manager.\n");
}