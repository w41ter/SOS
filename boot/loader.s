%include "boot.inc"

loader_stack_top equ loader_base_address

section loader vstart=loader_base_address
    jmp loader_start

gdt_base:   dd 0x00000000
            dd 0x00000000
code_desc:  dd 0x0000ffff
            dd desc_code_high4
data_stack_desc: dd 0x0000ffff
                 dd desc_data_high4
video_desc: dd 0x80000007
            dd desc_video_high4

gdt_size equ $ - gdt_base
gdt_limit equ gdt_size - 1

times 60 dq 0

selector_code equ (0x001 << 3) + TI_GDT + RPL0
selector_data equ (0x002 << 3) + TI_GDT + RPL0
selector_video equ (0x003 << 3) + TI_GDT + RPL0

gdt_ptr  dw gdt_limit
         dd gdt_base

loader_start:
    ; open A20
    in al, 0x92
    or al, 0x02
    out 0x92, al

    ; load gdt
    lgdt [gdt_ptr]

    ; cr0 
    mov eax, cr0
    or eax, 0x0001
    mov cr0, eax

    ; clear cache
    jmp dword selector_code: p_mode_start

[bits 32]
p_mode_start:
    mov ax, selector_data
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov esp, loader_stack_top
    mov ax, selector_video
    mov gs, ax

    mov byte [gs:160], 'P'

loop:
    nop
    jmp loop