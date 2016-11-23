// Boot loader.
//
// Part of the boot block, along with bootasm.s, which calls bootmain().
// bootasm.s has put the processor into protected 32-bit mode.
// bootmain() loads an ELF kernel image from the disk starting at
// sector 1 and then jumps to the kernel entry routine.

#include "types.h"
#include "elf.h"
#include "x86.h"

#define SECTSIZE 512

void read_segment(uint8_t *, uint32_t, uint32_t);

void bootmain(void)
{
	ELFHeader *elf;
	ProgramHeader *ph, *eph;
	void (*entry)(void);
	uint8_t *pa;

	elf = (ELFHeader *)0x10000; // scratch space

	// Read 1st page off disk
	read_segment((uint8_t *)elf, 4096, 0);

	// Is this an ELF executable?
	if (elf->magic != ELF_MAGIC)
		return; // let bootasm.S handle error

	// Load each program segment (ignores ph flags).
	ph = (ProgramHeader *)((uint8_t *)elf + elf->phoff);
	eph = ph + elf->phnum;
	for (; ph < eph; ph++)
	{
		pa = (uint8_t *)ph->paddr;
		read_segment(pa, ph->filesz, ph->off);
		if (ph->memsz > ph->filesz)
			stosb(pa + ph->filesz, 0, ph->memsz - ph->filesz);
	}

	// Call the entry point from the ELF header.
	// Does not return!
	entry = (void (*)(void))(elf->entry);
	entry();
}

void waitdisk(void)
{
	// Wait for disk ready.
	while ((inb(0x1F7) & 0xC0) != 0x40)
		;
}

// Read a single sector at offset into dst.
void read_sect(void *dst, uint32_t offset)
{
	// Issue command.
	waitdisk();
	outb(0x1F2, 1); // count = 1
	outb(0x1F3, offset);
	outb(0x1F4, offset >> 8);
	outb(0x1F5, offset >> 16);
	outb(0x1F6, (offset >> 24) | 0xE0);
	outb(0x1F7, 0x20); // cmd 0x20 - read sectors

	// Read data.
	waitdisk();
	insl(0x1F0, dst, SECTSIZE / 4);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
void read_segment(uint8_t *pa, uint32_t count, uint32_t offset)
{
	uint8_t *epa;

	epa = pa + count;

	// Round down to sector boundary.
	pa -= offset % SECTSIZE;

	// Translate from bytes to sectors; kernel starts at sector 1.
	offset = (offset / SECTSIZE) + 1;

	// If this is too slow, we could read lots of sectors at a time.
	// We'd write more to memory than asked, but it doesn't matter --
	// we load in increasing order.
	for (; pa < epa; pa += SECTSIZE, offset++)
		read_sect(pa, offset);
}
