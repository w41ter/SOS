%include "boot.inc"

loader_stack_top equ loader_base_address

selector_code equ (0x001 << 3) + TI_GDT + RPL0
selector_data equ (0x002 << 3) + TI_GDT + RPL0
selector_video equ (0x003 << 3) + TI_GDT + RPL0

section loader vstart=loader_base_address
;    jmp loader_start

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

; pos at 0xb00
total_mem_bytes dd 0

gdt_ptr  dw gdt_limit
         dd gdt_base

; aligin 256
ards_buf times 244 db 0
ards_nr            dw 0 

loader_start:

    ; int 15h
    ; eax = 0000e820h
    ; edx = 534d4150h
    xor ebx, ebx
    mov edx, 0x534d4150
    mov di, ards_buf
.e820_mem_get_loop:
    mov eax, 0x0000e820
    int 0x15
    jc .e820_failed_so_try_e801
    add di, cx
    inc word[ards_nr]
    cmp ebx, 0
    jnz .e820_mem_get_loop
    mov cx, [ards_nr]
    mov ebx, ards_buf
    xor edx, edx
.find_max_mem_area:
    mov eax, [ebx]
    add eax, [ebx+8]
    add ebx, 20
    cmp edx, eax
    jge .next_ards
    mov edx, eax
.next_ards
    loop .find_max_mem_area
    jmp .mem_get_ok

    ; int 15h 
    ; ax = e801h
.e820_failed_so_try_e801:
    mov ax, 0xe801
    int 0x15
    jc .e820_failed_so_try_88
    mov cx, 0x400
    mul cx
    shl edx, 16
    and eax, 0x0000ffff
    or edx, eax
    add edx, 0x100000
    mov esi, edx
    xor eax, eax
    mov ax, bx
    mov ecx, 0x10000
    mul ecx
    add esi, eax
    mov edx, esi
    jmp .mem_get_ok

    ; int 15h 
    ; ah = 0x88
    mov ah, 0x88
    int 0x15
    jc .error_hlt
    and eax, 0x0000ffff
    mov cx, 0x400
    mul cx
    shl edx, 16
    or edx, eax
    add edx, 0x100000

.mem_get_ok:
    mov [total_mem_bytes], edx


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