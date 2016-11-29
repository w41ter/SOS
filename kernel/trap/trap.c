#include <x86.h>
#include <mm/vmm.h>
#include <mm/segment.h>
#include <libs/types.h>
#include <libs/stdio.h>
#include <libs/debug.h>
#include <libs/string.h>
#include <driver/device.h>
#include <trap/traps.h>
#include <syscall/syscall.h>

#define IDT_DESC_CNT 0xff

#define IDT_DESC_P      1
#define IDT_DESC_DPL0   0
#define IDT_DESC_DPL3   3
#define IDT_DESC_32_TYPE 0xe
#define TRAP_DESC_32_TYPE 0xf

#define IDT_DESC_ATTR_DPL0 \
		((IDT_DESC_P << 7) + (IDT_DESC_DPL0 << 5) + IDT_DESC_32_TYPE)
#define IDT_DESC_ATTR_DPL3 \
		((IDT_DESC_P << 7) + (IDT_DESC_DPL3 << 5) + IDT_DESC_32_TYPE)

#define TRAP_DESC_ATTR_DPL0 \
		((IDT_DESC_P << 7) + (IDT_DESC_DPL0 << 5) + TRAP_DESC_32_TYPE)
#define TRAP_DESC_ATTR_DPL3 \
		((IDT_DESC_P << 7) + (IDT_DESC_DPL3 << 5) + TRAP_DESC_32_TYPE)

typedef void *InteruptHandle;

typedef struct GateDescriptor {
    uint16_t func_offset_low16;
    uint16_t selector;
    uint8_t  receved;
    uint8_t  attribute;
    uint16_t func_offset_high16;
} GateDescriptor;

static GateDescriptor idt[IDT_DESC_CNT];
extern InteruptHandle vectors[];

static const char * TrapName(int trapno) {
    static const char * const ExcNames[] = {
        "Divide error",
        "Debug",
        "Non-Maskable Interrupt",
        "Breakpoint",
        "Overflow",
        "BOUND Range Exceeded",
        "Invalid Opcode",
        "Device Not Available",
        "Double Fault",
        "Coprocessor Segment Overrun",
        "Invalid TSS",
        "Segment Not Present",
        "Stack Fault",
        "General Protection",
        "Page Fault",
        "(unknown trap)",
        "x87 FPU Floating-Point Error",
        "Alignment Check",
        "Machine-Check",
        "SIMD Floating-Point Exception"
    };

    if (trapno < sizeof(ExcNames)/sizeof(const char * const)) {
        return ExcNames[trapno];
    }
    if (trapno >= T_IRQ0 && trapno < T_IRQ0 + 16) {
        return "Hardware Interrupt";
    }
    return "(unknown trap)";
}

static void MakeTrapVecor(
    GateDescriptor *desc, uint8_t attr, InteruptHandle func)
{
    desc->func_offset_high16 = ((uint32_t)func & 0xffff0000) >> 16;
    desc->func_offset_low16 = (uint32_t)func & 0x0000ffff;
    desc->receved = 0;
    desc->selector = SEG_KCODE << 3;
    desc->attribute = attr;
}


/* *
 * These are arbitrarily chosen, but with care not to overlap
 * processor defined exceptions or interrupt vectors.
 * */
#define T_SWITCH_TO_U                120    // user/kernel switch
#define T_SWITCH_TO_K                121    // user/kernel switch

void TrapVectrosInitialize(void)
{
    for (int i = 0; i < IDT_DESC_CNT; ++i) {
        MakeTrapVecor(&idt[i], IDT_DESC_ATTR_DPL0, vectors[i]);
    }
	MakeTrapVecor(&idt[T_SYSCALL], TRAP_DESC_ATTR_DPL3, vectors[T_SYSCALL]);
}

void IDTInitialize(void) 
{
    printk("++ setup interrupt descriptor table\n");
    lidt(idt, sizeof(idt));
}

static const char *IA32flags[] = {
    "CF", NULL, "PF", NULL, "AF", NULL, "ZF", "SF",
    "TF", "IF", "DF", "OF", NULL, NULL, "NT", NULL,
    "RF", "VM", "AC", "VIF", "VIP", "ID", NULL, NULL,
};

/* trap_in_kernel - test if trap happened in kernel */
static bool IsTrapInKernel(TrapFrame *tf) 
{
    return (tf->cs == (uint16_t)SEG_KCODE << 3);
}

static void PrintRegs(TrapFrame *tf) 
{
    printk("  edi  0x%08x\n", tf->edi);
    printk("  esi  0x%08x\n", tf->esi);
    printk("  ebp  0x%08x\n", tf->ebp);
    printk("  oesp 0x%08x\n", tf->oesp);
    printk("  ebx  0x%08x\n", tf->ebx);
    printk("  edx  0x%08x\n", tf->edx);
    printk("  ecx  0x%08x\n", tf->ecx);
    printk("  eax  0x%08x\n", tf->eax);
}

void PrintTrapFrame(TrapFrame *tf) 
{
    printk("trapframe at %p\n", tf);
    PrintRegs(tf);
    printk("  ds   0x----%04x\n", tf->ds);
    printk("  es   0x----%04x\n", tf->es);
    printk("  fs   0x----%04x\n", tf->fs);
    printk("  gs   0x----%04x\n", tf->gs);
    printk("  trap 0x%08x %s\n", tf->trapno, TrapName(tf->trapno));
    printk("  err  0x%08x\n", tf->err);
    printk("  eip  0x%08x\n", tf->eip);
    printk("  cs   0x----%04x\n", tf->cs);
    printk("  flag 0x%08x ", tf->eflags);

    for (int i = 0, j = 1; i < sizeof(IA32flags) / sizeof(IA32flags[0]); i ++, j <<= 1) {
        if ((tf->eflags & j) && IA32flags[i] != NULL) {
            printk("%s,", IA32flags[i]);
        }
    }
    printk("IOPL=%d\n", (tf->eflags & FL_IOPL_MASK) >> 12);

    if (!IsTrapInKernel(tf)) {
        printk("  esp  0x%08x\n", tf->esp);
        printk("  ss   0x----%04x\n", tf->ss);
    }
}

/* DispatchTrap - dispatch based on what type of trap occurred */
static void DispatchTrap(TrapFrame *tf) 
{
    switch (tf->trapno) {
    case T_IRQ0 + IRQ_TIMER:
        ClockInterupt();
        break;
    case T_IRQ0 + IRQ_COM1:
        /* do nothing */
        break;
    case T_IRQ0 + IRQ_KBD:
        KeyboardInterupt();
        break;
    case T_PGFLT:
        OnPageFault(tf);
        break;
    case T_SYSCALL:
        SystemCall();
        break;
    case T_IRQ0 + IRQ_IDE1:
    case T_IRQ0 + IRQ_IDE2:
        /* do nothing */
        break;
    default:
        // in kernel, it must be a mistake
        if ((tf->cs & 3) == 0) {
            PrintTrapFrame(tf);
            panic("unexpected trap in kernel.\n");
        }
    }
}

void Trap(TrapFrame *tf) 
{
	DispatchTrap(tf);
}