#include "flags.h"

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
  # movw $(SEG_KDATA<<3), %ax
  # movw %ax, %ds
  # movw %ax, %es
  # movw $(SEG_KCPU<<3), %ax
  # movw %ax, %fs
  # movw %ax, %gs

  # Call Trap(tf), where tf=%esp
  pushl %esp
  call Trap
  addl $4, %esp
  jmp TrapRet

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
