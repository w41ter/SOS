#include "x86.h"
#include "mm/segment.h"

# vectors.S sends all traps here.
.globl AllTraps
AllTraps:
  # Build trap frame.
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs
  pushal
  
  # Set up data and per-cpu segments.
  movw $(KERNEL_DS), %ax
  movw %ax, %ds
  movw %ax, %es

  # Call Trap(tf), where tf=%esp
  pushl %esp
  call Trap
  popl %esp
 
  # Return falls through to TrapRet...
.globl TrapRet
TrapRet:
  popal
  popl %gs
  popl %fs
  popl %es
  popl %ds
  addl $0x8, %esp  # trapno and errcode  
  iret
