
OBJECTS = \
	main.o\
	entry.o\

VPATH = ./

CFLAGS += -I.
ASFLAGS += -I.

include ./libs/makefile
include ./driver/makefile
include ./mm/makefile
include ./trap/makefile

kernel: $(OBJECTS) kernel.ld
	@echo $(OBJECTS)
	$(LD) $(LDFLAGS) -T kernel.ld -o kernel $(OBJECTS)  -b binary  
	$(OBJDUMP) -S kernel > kernel.asm
	$(OBJDUMP) -t kernel | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' > kernel.sym

# for dependence
%.d: %.c
	$(CC) -MM $<

-include *.d

DEPENDENCE_FILES = $(patsubst %.o, %.d, $(OBJECTS)) 

.PHONY: clean
clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	$(OBJECTS) $(DEPENDENCE_FILES) *.asm *.sym trap/vectors.S kernel \
