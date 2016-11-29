#include <mm/slab.h>
#include <mm/vmm.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <proc/proc.h>

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
    process->runs = 0;
    process->kstack = 0;
    process->parent = NULL;
    process->tf = NULL;
    process->cr3 = GetInitializePageDirctory();
    process->flags = 0;
    process->counter = 0;
    list_node_init(&(process->processLink)); 
    memset(process->name, 0, PROC_NAME_LEN);
    memset(&(process->context), 0, sizeof(ProcessContext));
    return process;
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

//static ProcessControlBlock * AllocateProcess(void)
//{
//   
//}

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

void ProcessInitialize(void)
{
    printk("** setup process\n");
    list_init(&ProcessList);
    if ((idleProcess = AllocatePCB()) == NULL) {
        panic("cannot alloc idleProcess.\n");
    }

    extern char bootstack[];

    idleProcess->pid = AllocUniquePID();
    idleProcess->priority = 20;
    idleProcess->state = PS_Ready;
    idleProcess->kstack = (uintptr_t)bootstack;
    SetProcessName(idleProcess, "idle");
    list_append(&ProcessList, &idleProcess->processLink);
    numberOfProcess++;

    SetCurrentProcess(idleProcess);

    assert(idleProcess != NULL && idleProcess->pid == 0);
}