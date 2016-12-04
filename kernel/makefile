
OBJECTS = \
	main.o\
	entry.o\
	test.o\

VPATH = ./

CFLAGS += -I.
ASFLAGS += -I.

include ./libs/makefile
include ./driver/makefile
include ./mm/makefile
include ./trap/makefile
include ./syscall/makefile
include ./proc/makefile
include ./fs/makefile

kernelcontent: $(OBJECTS) kernel.ld initcode
	@echo $(OBJECTS)
	$(LD) $(LDFLAGS) -T kernel.ld -o kernelcontent $(OBJECTS) -b binary initcode 
	$(OBJDUMP) -S kernelcontent > kernel.asm
	$(OBJDUMP) -t kernelcontent | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

initcode: initcode.S
	$(CC) $(CFLAGS) -nostdinc -I. -c initcode.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0 -o initcode.out initcode.o
	$(OBJCOPY) -S -O binary initcode.out initcode
	$(OBJDUMP) -S initcode.o > initcode.asm

# for dependence
%.d: %.c
	$(CC) -MM $<

DEPENDENCE_FILES = $(patsubst %.o, %.d, $(OBJECTS)) 

-include $(DEPENDENCE_FILES)

.PHONY: clean
clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	$(OBJECTS) $(DEPENDENCE_FILES) *.asm *.sym \
	initcode initcode.out initcode.o initcode.d \
	trap/vectors.S kernelcontent \
