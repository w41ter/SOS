
# Try to infer the correct QEMU
ifndef QEMU
QEMU = $(shell if which qemu > /dev/null; \
	then echo qemu; exit; \
	elif which qemu-system-i386 > /dev/null; \
	then echo qemu-system-i386; exit; \
	else \
	qemu=/Applications/Q.app/Contents/MacOS/i386-softmmu.app/Contents/MacOS/i386-softmmu; \
	if test -x $$qemu; then echo $$qemu; exit; fi; fi; \
	echo "***" 1>&2; \
	echo "*** Error: Couldn't find a working QEMU executable." 1>&2; \
	echo "*** Is the directory containing the qemu binary in your PATH" 1>&2; \
	echo "*** or have you tried setting the QEMU variable in Makefile?" 1>&2; \
	echo "***" 1>&2; exit 1)
endif


# Try to infer the correct TOOLPREFIX if not set
ifndef TOOLPREFIX
TOOLPREFIX := $(shell if objdump -i 2>&1 | grep 'elf32-i386' >/dev/null 2>&1; \
	then echo ''; \
	else echo "***" 1>&2; \
	echo "*** Error: Couldn't find an i386-*-elf version of GCC/binutils." 1>&2; \
	echo "***" 1>&2; exit 1; fi)
endif

export CC = $(TOOLPREFIX)gcc
export AS = $(TOOLPREFIX)gas
export LD = $(TOOLPREFIX)ld
export OBJCOPY = $(TOOLPREFIX)objcopy
export OBJDUMP = $(TOOLPREFIX)objdump
export CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb -gstabs -m32 -Werror -fno-omit-frame-pointer -std=gnu99
#CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -fvar-tracking -fvar-tracking-assignments -O0 -g -Wall -MD -gdwarf-2 -m32 -Werror -fno-omit-frame-pointer
export CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)
export ASFLAGS = -m32  -Wa,-divide -gstabs  # -gdwarf-2

# FreeBSD ld wants ``elf_i386_fbsd''
export LDFLAGS += -m $(shell $(LD) -V | grep elf_i386 2>/dev/null)

VPATH = ./boot ./kernel

disk.img: boot kernel
	@echo "Building bootloader"
	make -C ./boot
	@echo "Building kernel"
	make -C ./kernel kernel
	@echo "Building image file"
	dd if=/dev/zero of=disk.img bs=512 count=10000
	dd if=boot/bootblock of=disk.img bs=512 count=1 conv=notrunc
	dd if=kernel/kernel of=disk.img bs=512 count=2000 seek=1 conv=notrunc

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)
	
ifndef CPUS
CPUS := 2
endif
QEMUOPTS = -drive file=disk.img,index=0,media=disk,format=raw -smp $(CPUS) -m 256 $(QEMUEXTRA)

qemu: disk.img
	$(QEMU) -serial mon:stdio $(QEMUOPTS)

qemu-nox: disk.img
	$(QEMU) -nographic $(QEMUOPTS)

.gdbinit: .gdbinit.tmpl
	sed "s/localhost:1234/localhost:$(GDBPORT)/" < $^ > $@

qemu-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -serial mon:stdio $(QEMUOPTS) -S $(QEMUGDB)

qemu-nox-gdb: disk.img .gdbinit
	@echo "*** Now run 'gdb'." 1>&2
	$(QEMU) -nographic $(QEMUOPTS) -S $(QEMUGDB)

.PHONY: clean
clean: 
	rm -f disk.img .gdbinit 
	make -C ./kernel clean
	make -C ./boot clean