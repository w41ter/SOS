#include "flags.h"

  # vectors.S sends all traps here.
.globl all_traps
all_traps:
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

  # Call trap(tf), where tf=%esp
  pushl %esp
  call trap
  addl $4, %esp
  jmp trap_ret

  # Return falls through to trap_ret...
.globl trap_ret
trap_ret:
  popal
  popl %gs
  popl %fs
  popl %es
  popl %ds
  addl $0x8, %esp  # trapno and errcode
  iret
