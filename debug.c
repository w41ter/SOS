#include "console.h"
#include "debug.h"
#include "types.h"
#include "x86.h"

#define ELF32_ST_TYPE(i) ((i)&0xf)

// ELF 格式区段头
typedef struct elf_section_header_t {
	uint32_t name;
	uint32_t type;
	uint32_t flags;
	uint32_t addr;
	uint32_t offset;
	uint32_t size;
	uint32_t link;
	uint32_t info;
	uint32_t addralign;
	uint32_t entsize;
} __attribute__((packed)) elf_section_header_t;

// ELF 格式符号
typedef struct elf_symbol_t {
	uint32_t name;
	uint32_t value;
	uint32_t size;
	uint8_t  info;
	uint8_t  other;
	uint16_t shndx;
} __attribute__((packed)) elf_symbol_t;

// ELF 信息
typedef struct elf_t {
	elf_symbol_t *symtab;
	uint32_t symtabsz;
	const char *strtab;
	uint32_t strtabsz;
} elf_t;

extern char __SYMTAB_BEGIN__[];
extern char __SYMTAB_END__[];
extern char __STRTAB_BEGIN__[];
extern char __STRTAB_END__[];

static const char *elf_lookup_symbol(uint32_t addr, elf_t *elf);

void panic(const char *msg)
{
    cli();
    
	printk("*** System panic: %s\n", msg);
	print_stack_trace();
	printk("***\n");
	
	// 致命错误发生后打印栈信息后停止在这里
	while(1) {
		hlt();
	}
}

void setup_kernel_elf(elf_t *elf)
{
    elf->strtab = __STRTAB_BEGIN__;
    elf->strtabsz = __STRTAB_END__ - __STRTAB_BEGIN__;
    elf->symtab = (elf_symbol_t*)__SYMTAB_BEGIN__;
    elf->symtabsz = __SYMTAB_END__ - __SYMTAB_BEGIN__;

    printk(".strtab:  %x = %x\n", elf->strtab, elf->strtabsz);
    printk(".symtab:  %x = %x\n", elf->symtab, elf->symtabsz);
}

void print_stack_trace(void)
{
	uint32_t *ebp, *eip;
    elf_t kernel_elf;

    setup_kernel_elf(&kernel_elf);

	__asm__ volatile ("mov %%ebp, %0" : "=r" (ebp));
	while (ebp) {
		eip = ebp + 1;
		printk("   [0x%x] %s\n", *eip, 
            elf_lookup_symbol(*eip, &kernel_elf));
		ebp = (uint32_t*)*ebp;
	}
}

static const char *elf_lookup_symbol(uint32_t addr, elf_t *elf)
{
    uint32_t i;
	for (i = 0; i < (elf->symtabsz / sizeof(elf_symbol_t)); i++) {
		if (ELF32_ST_TYPE(elf->symtab[i].info) != 0x2) {
		      continue;
		}
		// 通过函数调用地址查到函数的名字(地址在该函数的代码段地址区间之内)
		if ((addr >= elf->symtab[i].value) 
            && (addr < (elf->symtab[i].value + elf->symtab[i].size))) {
			return (const char *)((uint32_t)elf->strtab 
                + elf->symtab[i].name);
		}
	}

	return NULL;
}

void print_current_status(void)
{
	static int round = 0;
	uint16_t reg1, reg2, reg3, reg4;

	__asm__ volatile ( "mov %%cs, %0;"
			   "mov %%ds, %1;"
			   "mov %%es, %2;"
			   "mov %%ss, %3;"
			   : "=m"(reg1), "=m"(reg2), "=m"(reg3), "=m"(reg4));

	// 打印当前的运行级别
	printk("%d: @ring %d\n", round, reg1 & 0x3);
	printk("%d:  cs = %x\n", round, reg1);
	printk("%d:  ds = %x\n", round, reg2);
	printk("%d:  es = %x\n", round, reg3);
	printk("%d:  ss = %x\n", round, reg4);
	++round;
}

