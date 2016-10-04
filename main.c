#include "console.h"
#include "debug.h"
#include "types.h"
#include "flags.h"
#include "memlayout.h"
#include "memory.h"
#include "param.h"
#include "proc.h"
#include "segment.h"
#include "string.h"
#include "vm.h"
#include "x86.h"

extern pde_t kernel_pde[];
extern char end[];
extern int ismp;    // define at mp.c

void mpinit(void);
void seginit(void);
void lapicinit(void);
void pic_init(void);
void idt_init(void);
void timer_init(void);
void ioapic_init(void);
void trap_vector_init(void);

//__attribute__((noreturn))
static void mpmain(void);
void startothers(void);

int main(void) 
{
    console_clear();
    printk("Begin init kernel...\n");

    pmm_init();
    kvm_init();

    mpinit();
    lapicinit();
    seginit();

    pic_init();
    ioapic_init();
    console_init();

    proc_init();
    trap_vector_init();

    if(!ismp)
       timer_init();   // uniprocessor timer
       
    startothers();   // start other processors
    first_user_proc_init();
    mpmain();
    return 0;
}

int cpunum(void);

extern struct cpu cpus[NCPU];

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void seginit(void)
{
    struct cpu *c;

    // Map "logical" addresses to virtual addresses using identity map.
    // Cannot share a CODE descriptor for both kernel and user
    // because it would have to have DPL_USR, but the CPU forbids
    // an interrupt from CPL=0 to DPL=3.
    c = &cpus[cpunum()];
    c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
    c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
    c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
    c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);

    // Map cpu and curproc -- these are private per cpu.
    c->gdt[SEG_KCPU] = SEG(STA_W, &c->cpu, 8, 0);

    lgdt(c->gdt, sizeof(c->gdt));
    loadgs(SEG_KCPU << 3);

    // Initialize cpu-local storage.
    cpu = c;
    proc = 0;
}

// Common CPU setup code.
static void mpmain(void)
{
    printk("cpu%d: starting\n", cpu->id);
    idt_init();       // load idt register
    xchg(&cpu->started, 1); // tell startothers() we're up
    scheduler();     // start running processes 
}

// Other CPUs jump here from entryother.S.
static void mpenter(void)
{   
    switch_kvm();
    seginit();
    lapicinit();
    mpmain();
}

pde_t entrypgdir[];  // For entry.S
void lapicstartap(uint8_t apicid, uint32_t addr);

// Start the non-boot (AP) processors.
void startothers(void)
{
    extern uint8_t _binary_entryother_start[], _binary_entryother_size[];
    uint8_t *code;
    struct cpu *c;
    char *stack;

    // Write entry code to unused memory at 0x7000.
    // The linker has placed the image of entryother.S in
    // _binary_entryother_start.
    code = P2V(0x7000);
    memmove(code, _binary_entryother_start, (uint32_t)_binary_entryother_size);

    for(c = cpus; c < cpus+ncpu; c++){
        if(c == cpus+cpunum())  // We've started already.
        continue;

        // Tell entryother.S what stack to use, where to enter, and what
        // pgdir to use. We cannot use kpgdir yet, because the AP processor
        // is running in low  memory, so we use entrypgdir for the APs too.
        stack = (char *)kalloc();
        *(void**)(code-4) = stack + KSTACKSIZE;
        *(void**)(code-8) = mpenter;
        *(int**)(code-12) = (void *) V2P(entrypgdir);

        lapicstartap(c->id, V2P(code));

        // wait for cpu to finish mpmain()
        printk(" wait ...\n");
        while(c->started == 0)
        ;
        printk(" end wait\n");
    }
}

// The boot page table used in entry.S and entryother.S.
// Page directories (and page tables) must start on page boundaries,
// hence the __aligned__ attribute.
// PTE_PS in a page directory entry enables 4Mbyte pages.

__attribute__((__aligned__(PAGE_SIZE)))
pde_t entrypgdir[NPDENTRIES] = {
    // Map VA's [0, 4MB) to PA's [0, 4MB)
    [0] = (0) | PTE_P | PTE_W | PTE_PS,
    // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
    [KERNEL_BASE>>PDX_SHIFT] = (0) | PTE_P | PTE_W | PTE_PS,
};
