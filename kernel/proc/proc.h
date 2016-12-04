#pragma once

#include <mm/vmm.h>
#include <libs/list.h>
#include <libs/types.h>
#include <trap/traps.h>

// process's state in his life cycle.
enum ProcessState {
    PS_Created = 0,
    PS_Running,
    PS_Sleeping,
    PS_Ready,
    PS_Terminated,  // almost dead, and wait parent procsee
                    // to re claim his resource.
};

// Saved registers for kernel context switches.
// Don't need to save all the %fs etc. segment registers,
// because they are constant across kernel contexts.
// Save all the regular registers so we don't need to care
// which are caller save, but not the return register %eax.
// (Not saving %eax just simplifies the switching code.)
// The layout of context must match code in switch.S.
typedef struct ProcessContext {
    uint32_t eip;
    uint32_t esp;
    uint32_t ebx;
    uint32_t ecx;
    uint32_t edx;
    uint32_t esi;
    uint32_t edi;
    uint32_t ebp;
} ProcessContext;

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

typedef struct ProcessControlBlock {
    enum ProcessState state;                    // Process state
    int exitCode;                              // exit code (be sent to parent proc)
    int counter;                             // time slice for occupying the CPU
    int pid;                                    // Process ID
    bool killed;                                // 
    uint32_t priority;                          // Process schedule priority
    uint32_t flags;                             // Process flag
    uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
    char * kstack;                           // Process kernel stack
    TrapFrame *tf;                              // Trap frame for current interrupt
    MemoryLayout *mm;
    struct ProcessControlBlock *parent;         // the parent process
    char name[PROC_NAME_LEN + 1];               // Process name
    struct list_node_t processLink;                     // Process link list
    ProcessContext context;                     // Switch here to run process
} ProcessControlBlock;

#define GET_PCB_FROM_LIST_NODE(ptr) (list_get(ptr, ProcessControlBlock, processLink));

void SetupProcessManager(void);

ProcessControlBlock * GetCurrentProcess(void);
void SetCurrentProcess(ProcessControlBlock *pcb);

int ProcessFork(void);
void ProcessYield(void);
void ProcessExit(int exitCode);
void ProcessSleep(void);
void ProcessWakeup(ProcessControlBlock *process);