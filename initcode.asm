
initcode.o:     file format elf32-i386


Disassembly of section .text:

00000000 <start>:

# for(;;) exit();
exit:
  #movl $SYS_exit, %eax
  #int $T_SYSCALL
  jmp exit
   0:	eb fe                	jmp    0 <start>

00000002 <init>:
   2:	2f                   	das    
   3:	69 6e 69 74 00 00 8d 	imul   $0x8d000074,0x69(%esi),%ebp
   a:	76 00                	jbe    c <argv>

0000000c <argv>:
   c:	02 00                	add    (%eax),%al
   e:	00 00                	add    %al,(%eax)
  10:	00 00                	add    %al,(%eax)
	...
