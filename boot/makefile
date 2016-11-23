
bootblock: bootasm.S bootmain.c 
	$(CC) $(CFLAGS) -fno-pic -O -nostdinc -I. -I../kernel/ -c bootmain.c
	$(CC) $(CFLAGS) -fno-pic -nostdinc -I. -I../kernel/ -c bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o bootblock.o bootasm.o bootmain.o
	$(OBJDUMP) -S bootblock.o > bootblock.asm
	$(OBJCOPY) -S -O binary -j .text bootblock.o bootblock
	./sign.pl bootblock

.PHONY: clean
clean: 
	rm -f *.tex *.dvi *.idx *.aux *.log *.ind *.ilg \
	*.o *.d *.asm bootblock \
