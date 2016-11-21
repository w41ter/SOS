#include "console.h"
#include "debug.h"
#include "param.h"
#include "proc.h"
#include "spinlock.h"
#include "string.h"
#include "types.h"
#include "vm.h"

struct {
  struct spinlock lock;
  struct proc proc[NPROC];
} ptable;

static struct proc *initproc;

int nextpid = 1;

void fork_ret(void);
extern void trap_ret(void);

void proc_init(void)
{
    init_lock(&ptable.lock, "ptable");
}

// Look in the process table for an UNUSED proc.
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
// Must hold ptable.lock.
static struct proc *alloc_proc(void)
{
    struct proc *p;
    char *sp;

    printk("  alloc_proc: begin...\n");
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
        if(p->state == UNUSED)
        goto found;
    return 0;

found:
    p->state = EMBRYO;
    p->pid = nextpid++;

    // Allocate kernel stack.
    if ((p->kstack = (char*)kalloc()) == 0) {
        p->state = UNUSED;
        return 0;
    }
    sp = p->kstack + KSTACKSIZE;

    // Leave room for trap frame.
    sp -= sizeof(*p->tf);
    p->tf = (struct trap_frame*)sp;

    // Set up new context to start executing at fork_ret,
    // which returns to trap_ret.
    sp -= 4;
    *(uint32_t*)sp = (uint32_t)trap_ret;

    sp -= sizeof(*p->context);
    p->context = (struct context*)sp;
    memset(p->context, 0, sizeof(*p->context));
    p->context->eip = (uint32_t)fork_ret;

    block_desc_init(p->ublocks);

    return p;
}

void first_user_proc_init(void)
{
    struct proc *p;
    extern char _binary_initcode_start[], _binary_initcode_size[];

    printk("first_user_proc_init...\n");

    acquire(&ptable.lock);

    p = alloc_proc();
    initproc = p;
    if ((p->pgdir = setup_kvm()) == 0)
        panic("userinit: out of memory?");
    init_uvm(p->pgdir, _binary_initcode_start, 
        (uint32_t)_binary_initcode_size);
  
    printk("first_user_proc_init: try to init base infor...\n");
    p->sz = PAGE_SIZE;
    memset(p->tf, 0, sizeof(*p->tf));
    p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
    p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
    p->tf->es = p->tf->ds;
    p->tf->ss = p->tf->ds;
    p->tf->eflags = FL_IF;
    p->tf->esp = PAGE_SIZE; // 0 + PAGE_SIZE;
    p->tf->eip = 0;  // beginning of initcode.S

    // todo:
    safestrcpy(p->name, "initcode", sizeof(p->name));
    //p->cwd = namei("/");

    p->state = RUNNABLE;

    release(&ptable.lock);
}

// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int fork(void) 
{
    int pid;
    struct proc *p;

    acquire(&ptable.lock);

    if ((p = alloc_proc()) == 0) {
        release(&ptable.lock);
        return -1;
    }

    if ((p->pgdir = copy_uvm(proc->pgdir)) == 0) {
        kfree_pages((uint32_t)p->kstack, 1);
        p->kstack = 0;
        p->state = UNUSED;
        release(&ptable.lock);
        return -1;
    }
    p->sz = proc->sz;
    p->parent = proc;
    *p->tf = *proc->tf;

    // Clear %eax so that fork returns 0 in the child.
    p->tf->eax = 0;

    // for(i = 0; i < NOFILE; i++)
    //     if(proc->ofile[i])
    //     p->ofile[i] = filedup(proc->ofile[i]);
    // p->cwd = idup(proc->cwd);

    safestrcpy(p->name, proc->name, sizeof(proc->name));

    pid = p->pid;

    p->state = RUNNABLE;

    release(&ptable.lock);

    return pid;
}

static void wakeup1(void *chan)
{
    struct proc *p;

    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++)
        if (p->state == SLEEPING && p->chan == chan)
            p->state = RUNNABLE;
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void exit(void)
{
    struct proc *p;
    //int fd;

    if(proc == initproc)
        panic("init exiting");

    // Close all open files.
    // for(fd = 0; fd < NOFILE; fd++){
    //     if(proc->ofile[fd]){
    //     fileclose(proc->ofile[fd]);
    //     proc->ofile[fd] = 0;
    //     }
    // }

    // begin_op();
    // iput(proc->cwd);
    // end_op();
    proc->cwd = 0;

    acquire(&ptable.lock);

    // Parent might be sleeping in wait().
    wakeup1(proc->parent);

    // Pass abandoned children to init.
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
        if (p->parent == proc) {
            p->parent = initproc;
            if (p->state == ZOMBIE)
                wakeup1(initproc);
        }
    }

    // Jump into the scheduler, never to return.
    proc->state = ZOMBIE;
    sched();
    panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(void)
{
    struct proc *p;
    int havekids, pid;

    acquire(&ptable.lock);
    for (;;) {
        // Scan through table looking for zombie children.
        havekids = 0;
        for(p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
            if(p->parent != proc)
                continue;
            havekids = 1;
            if(p->state == ZOMBIE) {
                // Found one.
                pid = p->pid;
                kfree_pages((uint32_t)p->kstack, 1);
                p->kstack = 0;
                free_vm(p->pgdir);
                p->pid = 0;
                p->parent = 0;
                p->name[0] = 0;
                p->killed = 0;
                p->state = UNUSED;
                release(&ptable.lock);
                return pid;
            }
        }

        // No point waiting if we don't have any children.
        if (!havekids || proc->killed) {
            release(&ptable.lock);
            return -1;
        }

        // Wait for children to exit.  (See wakeup1 call in proc_exit.)
        sleep(proc, &ptable.lock);  //DOC: wait-sleep
    }
}

extern void swtch(struct context**, struct context*); 

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void scheduler(void)
{
    struct proc *p;

    printk("CPU%d begin scheduler...\n", cpu->id);

    for(;;) {
        // Enable interrupts on this processor.
        //sti();

        // Loop over process table looking for process to run.
        acquire(&ptable.lock);
        for(p = ptable.proc; p < &ptable.proc[NPROC]; p++) {  
        if(p->state != RUNNABLE)
            continue;

        printk("  now CPU%d begin run process %d\n", cpu->id, p->pid); 
  
        // Switch to chosen process.  It is the process's job
        // to release ptable.lock and then reacquire it
        // before jumping back to us.
        proc = p;
        switch_uvm(p);
        p->state = RUNNING;
        printk("scheduler: begin swtch...\n");
        uint32_t *stack = (uint32_t*)p->context;
        stack += sizeof(p->context);
        assert(*stack == (uint32_t)fork_ret);
        swtch(&cpu->scheduler, p->context);
        switch_kvm();

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        proc = 0;
        }
        release(&ptable.lock);
    }
}

// Give up the CPU for one scheduling round.
void yield(void)
{
    acquire(&ptable.lock);  //DOC: yieldlock
    proc->state = RUNNABLE;
    sched();
    release(&ptable.lock);
}

// Enter scheduler.  Must hold only ptable.lock
// and have changed proc->state.
void sched(void)
{
    int intena;

    if(!holding(&ptable.lock))
        panic("sched ptable.lock");
    if(cpu->ncli != 1)
        panic("sched locks");
    if(proc->state == RUNNING)
        panic("sched running");
    if(readeflags()&FL_IF)
        panic("sched interruptible");
    intena = cpu->intena;
    swtch(&proc->context, cpu->scheduler);
    cpu->intena = intena;
}

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void fork_ret(void)
{
    static int first = 1;
    
    printk("  fork_ret: begin...\n");
    // Still holding ptable.lock from scheduler.
    release(&ptable.lock);

    if (first) {
        // Some initialization functions must be run in the context
        // of a regular process (e.g., they call sleep), and thus cannot
        // be run from main().
        first = 0;
        //iinit(ROOTDEV);
        //initlog(ROOTDEV);
    }

    printk(" Return to \"caller\"\n");
    hlt();
    // Return to "caller", actually trapret (see allocproc).
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    if (proc == 0)
        panic("sleep");

    if (lk == 0)
        panic("sleep without lk");

    // Must acquire ptable.lock in order to
    // change p->state and then call sched.
    // Once we hold ptable.lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup runs with ptable.lock locked),
    // so it's okay to release lk.
    if (lk != &ptable.lock) {  //DOC: sleeplock0
        acquire(&ptable.lock);  //DOC: sleeplock1
        release(lk);
    }

    // Go to sleep.
    proc->chan = chan;
    proc->state = SLEEPING;
    sched();

    // Tidy up.
    proc->chan = 0;

    // Reacquire original lock.
    if (lk != &ptable.lock) {  //DOC: sleeplock2
        release(&ptable.lock);
        acquire(lk);
    }
}

// Wake up all processes sleeping on chan.
void wakeup(void *chan)
{
    acquire(&ptable.lock);
    wakeup1(chan);
    release(&ptable.lock);
}

// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int kill(int pid)
{
    struct proc *p;

    acquire(&ptable.lock);
    for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
        if(p->pid == pid) {
            p->killed = 1;
            // Wake process from sleep if necessary.
            if(p->state == SLEEPING)
                p->state = RUNNABLE;
            release(&ptable.lock);
            return 0;
        }
    }
    release(&ptable.lock);
    return -1;
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    // static char *states[] = {
    //     [UNUSED]    "unused",
    //     [EMBRYO]    "embryo",
    //     [SLEEPING]  "sleep ",
    //     [RUNNABLE]  "runble",
    //     [RUNNING]   "run   ",
    //     [ZOMBIE]    "zombie"
    // };
    // int i;
    // struct proc *p;
    // char *state;
    // uint pc[10];

    // for (p = ptable.proc; p < &ptable.proc[NPROC]; p++) {
    //     if(p->state == UNUSED)
    //         continue;
    //     if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    //         state = states[p->state];
    //     else
    //         state = "???";
    //     printk("%d %s %s", p->pid, state, p->name);
    //     // if (p->state == SLEEPING) {
    //     //     getcallerpcs((uint*)p->context->ebp+2, pc);
    //     //     for (i=0; i<10 && pc[i] != 0; i++)
    //     //         cprintk(" %p", pc[i]);
    //     // }
    //     printk("\n");
    // }
}
