#include <x86.h>
#include <param.h>
#include <mm/mm.h>
#include <libs/atomic.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <proc/proc.h>
#include <proc/spinlock.h>
#include <proc/schedule.h>
#include <trap/traps.h>

struct list_t ProcessList;

static SpinLock ProcessListLock;

static ProcessControlBlock *idleProcess = NULL;   // idle proc
static ProcessControlBlock *initProcess = NULL;   // init proc
static ProcessControlBlock *current = NULL;    // current proc
static uint32_t numberOfProcess = 0;

static struct atomic_t currentPID = ATOMIC_INIT(-1);

static ProcessControlBlock * AllocatePCB(void) {
    ProcessControlBlock *process = kmalloc(sizeof(ProcessControlBlock));
    if (process == NULL) 
        return NULL;
    
    process->state = PS_Created;
    process->pid = -1;
    process->kstack = NULL;
    process->parent = NULL;
    process->tf = NULL;
    process->mm = NULL;
    process->killed = false;
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


static void ProcessListInsert(ProcessControlBlock *proc)
{
    assert(proc && "nullptr exception");
    printk("insert process pid=%d\n", proc->pid);
    Acquire(&ProcessListLock);
    list_append(&ProcessList, &proc->processLink);
    numberOfProcess++;
    Release(&ProcessListLock);
}

static void ProcessListRemove(ProcessControlBlock *proc)
{
    assert(proc && "nullptr exception");
    assert(list_node_has_parent(&proc->processLink));

    Acquire(&ProcessListLock);
    list_remove(&proc->processLink);
    numberOfProcess--;
    Release(&ProcessListLock);
}

// get_pid - alloc a unique pid for process
static uint32_t AllocUniquePID(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    if (MAX_PID <= atomic_read(&currentPID))
        panic("all pid used.");
    return atomic_inc_return(&currentPID);
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
    process->priority = 3;  
    
    // Allocate kernel stack.
    if ((process->kstack = AllocateStack()) == NULL) {
        ReleasePCB(process);
        return NULL;
    }
    char *stack = process->kstack + KSTACKSIZE;

    // Leave room for trap frame
    stack -= sizeof(*process->tf);
    process->tf = (TrapFrame*)stack;
    process->tf->eflags |= FL_IF;
    memset(&process->context, 0, sizeof(process->context));
    process->context.eip = (uint32_t)TrapRet;
    process->context.esp = (uint32_t)process->tf;
    
    return process;
}

static int CopyMemoryLayout(ProcessControlBlock *proc, MemoryLayout *pmm)
{
    assert(proc && proc->mm == NULL);

    proc->mm = MemoryLayoutCreate();
    if (proc->mm == NULL) {
        return -1;
    }

    proc->mm->pgdir = SetupPageDirectory();
    if (proc->mm->pgdir == NULL) 
        goto SETUP_PAGE_FALSE;

    if (CopyMemoryMap(pmm, proc->mm) != 0)
        goto COPY_MEMORY_MAP_FALSE;

    return 0;

COPY_MEMORY_MAP_FALSE:
    ExitMemoryMap(proc->mm);
    DestroyPageDirectory(proc->mm->pgdir);

SETUP_PAGE_FALSE:
    DestroyMemoryLayout(proc->mm);
    proc->mm = NULL;
    return -1;
}

static void ReleaseMemoryLayout(ProcessControlBlock *proc)
{
    if (proc->mm != NULL) {
        ExitMemoryMap(proc->mm);
        DestroyPageDirectory(proc->mm->pgdir);
        DestroyMemoryLayout(proc->mm);
    }
    proc->mm = NULL;
}

static void ReleaseProcess(ProcessControlBlock *process)
{
    ReleaseMemoryLayout(process);
    FreeStack(process->kstack);
    process->kstack = NULL;

    if (list_node_has_parent(&process->processLink))
        ProcessListRemove(process);

    ReleasePCB(process);
}

int ProcessFork(void)
{
    ProcessControlBlock *process = ProcessCreate();
    if (process == NULL)
        return -1;

    ProcessControlBlock *current = GetCurrentProcess();
    process->parent = current;

    /* setup page dir & copy memory map */
    if (CopyMemoryLayout(process, current->mm) != 0)
        goto FAIL;

    /* Copy trap frame so that child like 
    same as parent when exit kernel mode. */
    *process->tf = *current->tf; 

    /* Clear %eax so that fork return 0 in the child. */
    process->tf->eax = 0;

    // TODO: Copy file  

    SetProcessName(process, current->name);
    process->state = PS_Ready;
    ProcessListInsert(process);

    return process->pid;

FAIL:
    ReleaseProcess(process);
    return -1;
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

    // FIXME: remove goto
    // Pass abandoned children to idle.
    Acquire(&ProcessListLock);
    list_for_each(node, &ProcessList) {
        ProcessControlBlock *child;
    BEGIN:
        child = GET_PCB_FROM_LIST_NODE(node);
        if (child->parent != current)
            continue;
        
        if (child->state == PS_Terminated) {
            node = list_node_next(node);
            ReleaseProcess(child);
            if (node != list_end())
                goto BEGIN;
            else 
                break;
        }
        child->parent = idleProcess;
    }
    Release(&ProcessListLock);

    // Jump into the scheduler, never to return.
    current->state = PS_Terminated;
    current->exitCode = exitCode;
    Schedule();
    panic("Terminated exit");
}

void ProcessWakeup(ProcessControlBlock *process)
{
    if (process->state == PS_Sleeping)
        process->state = PS_Ready;
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
                ReleaseProcess(process);
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

// Call by schedule 
void ProcessClearTerminated(void)
{
    ProcessControlBlock *current = GetCurrentProcess();
    assert(current == idleProcess);

    Acquire(&ProcessListLock);

    list_for_each(node, &ProcessList) {
        ProcessControlBlock *child;
    BEGIN:
        child = GET_PCB_FROM_LIST_NODE(node);
        if (child->state == PS_Terminated) {
            node = list_node_next(node);
            ReleaseProcess(child);
            if (node != list_end())
                goto BEGIN;
            else 
                break;
        }
    }
    Release(&ProcessListLock);
}

static void SetupInitProcess(void)
{
    extern char _binary_initcode_start[], _binary_initcode_size[];

    printk(" [+] setup init process\n");
    if ((initProcess = ProcessCreate()) == NULL) {
        panic("cannot alloc initProcess.\n");
    }

    initProcess->mm = MemoryLayoutCreate();
    if (initProcess->mm == NULL) {
        panic("cannot alloc initProcess.\n");
    }

    InitUserVM(initProcess->mm, _binary_initcode_start,
        (int)_binary_initcode_size);

    memset(initProcess->tf, 0, sizeof(*initProcess->tf));
    initProcess->tf->cs = USER_CS;
    initProcess->tf->ds = USER_DS;
    initProcess->tf->es = initProcess->tf->ds;
    initProcess->tf->ss = initProcess->tf->ds;
    initProcess->tf->eflags = FL_IF;
    initProcess->tf->esp = USER_BASE + PAGE_SIZE;
    initProcess->tf->eip = USER_BASE;  // beginning of initcode.S
    initProcess->state = PS_Ready;
    SetProcessName(initProcess, "initcode");
    
    ProcessListInsert(initProcess);
}

static void SetupIdleProcess(void) 
{
    extern char bootstack[];

    printk(" [+] setup idle process\n");
    if ((idleProcess = AllocatePCB()) == NULL) {
        panic("cannot alloc idleProcess.\n");
    }

    idleProcess->pid = AllocUniquePID();
    idleProcess->priority = 3;
    idleProcess->state = PS_Ready;
    idleProcess->kstack = bootstack;
    SetProcessName(idleProcess, "idle");
    ProcessListInsert(idleProcess);

    SetCurrentProcess(idleProcess);

    assert(idleProcess != NULL && idleProcess->pid == 0);
}

void SetupProcessManager(void)
{
    printk("** setup process manager.\n");
    list_init(&ProcessList);
    InitSpinLock(&ProcessListLock, "process list lock");

    SetupIdleProcess();
    SetupInitProcess();
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

int ProcessGetPID(void)
{
    ProcessControlBlock *current = GetCurrentProcess();
    return current->pid;
}