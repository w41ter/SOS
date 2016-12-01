#include <param.h>
#include <mm/vmm.h>
#include <mm/pmm.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <proc/proc.h>
#include <proc/schedule.h>
#include <trap/traps.h>

struct list_t ProcessList;

static ProcessControlBlock *idleProcess = NULL;   // idle proc
// static ProcessControlBlock *initProcess = NULL;   // init proc
static ProcessControlBlock *current = NULL;    // current proc
static uint32_t numberOfProcess = 0;
static uint32_t currentPID = 0;

static ProcessControlBlock * AllocatePCB(void) {
    ProcessControlBlock *process = kmalloc(sizeof(ProcessControlBlock));
    if (process == NULL) 
        return NULL;
    
    process->state = PS_Created;
    process->pid = -1;
    process->kstack = NULL;
    process->parent = NULL;
    process->tf = NULL;
    process->killed = false;
    process->cr3 = GetInitializePageDirctory();
    process->flags = 0;
    process->counter = 0;
    list_node_init(&(process->processLink)); 
    memset(process->name, 0, PROC_NAME_LEN);
    memset(&(process->context), 0, sizeof(ProcessContext));
    return process;
}

static void ReleasePCB(ProcessControlBlock *process) 
{
    assert(process && "nullptr exception");
    kfree(process);
}

static void SetProcessName(ProcessControlBlock *process, const char *name)
{
    assert(process && name && "nullptr exception.");
    strncpy(process->name, name, PROC_NAME_LEN);
}

// static const char * GetProcessName(ProcessControlBlock *process)
// {
//     assert(process && "nullptr exception");
//     return process->name;
// }

// get_pid - alloc a unique pid for process
static uint32_t AllocUniquePID(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    if (MAX_PID <= currentPID)
        panic("all pid used.");
    return currentPID++;
}

static void *AllocateStack(void)
{
    static_assert(KSTACKSIZE == PAGE_SIZE);
    Page *page = PhysicAllocatePage();
    if (page == NULL) 
        return NULL;
    return PageToVirtualAddress(page);
}

static void FreeStack(void *stack)
{
    Page *page = VirtualAddressToPage(stack);
    PhysicFreePage(page);
}

/**
 *  +-----------------------+
 *  |     trap frame        |
 *  +-----------------------+
 *  |     ....              |
 *  +-----------------------+
 */
static ProcessControlBlock * ProcessCreate(void) 
{
    ProcessControlBlock *process = AllocatePCB();
    if (process == NULL)
        return NULL;
    process->pid = AllocUniquePID();
    process->priority = 2;  
    
    // Allocate kernel stack.
    if ((process->kstack = AllocateStack()) == NULL) {
        ReleasePCB(process);
        return NULL;
    }
    char *stack = process->kstack + KSTACKSIZE;

    // Leave room for trap frame
    stack -= sizeof(*process->tf);
    process->tf = (TrapFrame*)stack;

    memset(&process->context, 0, sizeof(process->context));

    process->context.eip = (uint32_t)TrapRet;
    process->context.esp = (uint32_t)process->tf;
    
    return process;
}

int ProcessFork(void)
{
    ProcessControlBlock *process = ProcessCreate();
    if (process == NULL) {
        return -1;
    }

    // TODO: Copy process state from p.

    ProcessControlBlock *current = GetCurrentProcess();
    process->parent = current;

    // Copy trap frame so that child like same as parent.
    *process->tf = *current->tf; 

    // Clear %eax so that fork return 0 in the child.
    process->tf->eax = 0;

    // TODO: Copy file    
    strncpy(process->name, current->name, sizeof(process->name));

    process->state = PS_Ready;
    list_append(&ProcessList, &process->processLink);

    return process->pid;
}

// Exit the current process.  Does not return.
// An exited process remains in the terminated state
// until its parent calls wait() to find out it exited.
void ProcessExit(int exitCode)
{
    ProcessControlBlock *current = GetCurrentProcess();

    // TODO: close file.

    // Parent might in sleep.
    ProcessWakeup(current->parent);

    // FIXME: remove ...
    // Pass abandoned children to idle.
    list_for_each(node, &ProcessList) {
        ProcessControlBlock *child = GET_PCB_FROM_LIST_NODE(node);
        if (child->parent == current) {
            child->parent = idleProcess;
        }
    }

    // Jump into the scheduler, never to return.
    current->state = PS_Terminated;
    current->exitCode = exitCode;
    Schedule();
    panic("Terminated exit");
}

void ProcessWakeup(ProcessControlBlock *process)
{
    // TODO:
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
void ProcessWait()
{
    panic("error\n");
    bool haveKids = false;
    for (;;) {
        ProcessControlBlock *current = GetCurrentProcess();
        list_for_each(node, &ProcessList) {
            ProcessControlBlock *process = GET_PCB_FROM_LIST_NODE(node);
            if (process->parent != current)
                continue;
            haveKids = true;
            if (process->state == PS_Terminated) {
                // Found one.
                FreeStack(process->kstack);
                ReleasePCB(process);
            }
        }

        // No point waiting if we don't have any children.
        if (!haveKids || current->killed) {
            return ;
        }

        // Wait for children to exit.  (See wakeup1 call in proc_exit.)
        ProcessSleep();
    }
}

void ProcessSleep(void)
{
    ProcessControlBlock *current = GetCurrentProcess();
    current->state = PS_Sleeping;
    Schedule();
}

// Give up the CPU for one scheduling round.
void ProcessYield(void)
{
    ProcessControlBlock *current = GetCurrentProcess();
    current->state = PS_Ready;
    Schedule();
}

void ProcessInitialize(void)
{
    printk("** setup process\n");
    list_init(&ProcessList);
    if ((idleProcess = AllocatePCB()) == NULL) {
        panic("cannot alloc idleProcess.\n");
    }

    extern char bootstack[];

    idleProcess->pid = AllocUniquePID();
    idleProcess->priority = 1;
    idleProcess->state = PS_Ready;
    idleProcess->kstack = bootstack;
    SetProcessName(idleProcess, "idle");
    list_append(&ProcessList, &idleProcess->processLink);
    numberOfProcess++;

    SetCurrentProcess(idleProcess);

    assert(idleProcess != NULL && idleProcess->pid == 0);
}

ProcessControlBlock * GetCurrentProcess(void)
{
    assert(current && "nullptr exception");
    return current;
}

void SetCurrentProcess(ProcessControlBlock *pcb)
{
    assert(pcb && "nullptr exception");
    current = pcb;
}