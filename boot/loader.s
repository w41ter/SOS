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
.next_ards:
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
.e820_failed_so_try_88:
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

.error_hlt:
    ; show message and down
    nop
    nop
    nop
    jmp $

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

    ; load kernel
    mov eax, kernel_start_sector
    mov ebx, kernel_bin_base_address
    mov ecx, 200
    call rd_disk_m_32

    call setup_page

    sgdt [gdt_ptr]
    mov ebx, [gdt_ptr + 2]
    or dword [ebx + 0x18 + 4], 0xc000000
    add dword [gdt_ptr + 2], 0xc000000
    add esp, 0xc000000
    
    ; set cr3
    mov eax, page_dir_table_base
    mov cr3, eax

    ; open cr0 pg
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    ; load gdt
    lgdt [gdt_ptr]
    
    jmp selector_code: enter_kernel
enter_kernel:
    call kernel_init
    mov esp, 0xc009f000
    jmp kernel_entey_point

setup_page:
    mov ecx, 4096
    mov esi, 0
.clear_page_dir:
    mov byte[page_dir_table_base + esi], 0
    inc esi
    loop .clear_page_dir
.create_pde:
    mov eax, page_dir_table_base
    add eax, 0x1000
    mov ebx, eax
    or eax, PG_US_U | PG_RW_W | PG_P
    mov [page_dir_table_base + 0x0], eax
    mov [page_dir_table_base + 0xc00], eax
    sub eax, 0x1000
    mov [page_dir_table_base + 4092], eax
    mov ecx, 256
    mov esi, 0
    mov edx, PG_US_U | PG_RW_W | PG_P
.create_pte:
    mov [ebx + esi*4], edx
    add edx, 4096
    inc esi
    loop .create_pte

    mov eax, page_dir_table_base
    add eax, 0x2000
    or eax, PG_US_U | PG_RW_W | PG_P
    mov ebx, page_dir_table_base
    mov ecx, 254
    mov esi, 769
.create_kernel_pte:
    mov [ebx + esi*4], eax
    inc esi
    add eax, 0x1000
    loop .create_kernel_pte
    ret

kernel_init:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

    mov dx, [kernel_bin_base_address + 42]
    mov ebx, [kernel_bin_base_address + 28]
    add ebx, kernel_bin_base_address
    mov cx, [kernel_bin_base_address + 34]

.each_segment:
    cmp byte [ebx + 0], PT_NULL
    je .PTNULL
    push dword [ebx + 16]
    mov eax, [ebx + 4]
    add eax, kernel_bin_base_address
    push eax
    push dword [ebx + 8]
    call mem_cpy
    add esp, 12
.PTNULL:
    add ebx, edx
    loop .each_segment
    ret

mem_cpy:
    cld
    push ebp
    mov ebp, esp
    push ecx

    mov edi, [ebp + 8]
    mov esi, [ebp + 12]
    mov ecx, [ebp + 16]
    rep movsb

    pop ecx
    pop ebp
    ret

rd_disk_m_32:
    mov esi, eax
    mov dx, cx

    mov dx, 0x1f2
    mov al, cl
    out dx, al

    mov eax, esi
    
    mov dx, 0x1f3
    out dx, al

    mov cl, 8
    shr eax, cl
    mov dx, 0x1f4
    out dx, al

    shr eax, cl
    mov dx, 0x1f5
    out dx, al
    
    shr eax, cl
    and al, 0x0f
    or al, 0xe0
    mov dx, 0x1f6
    out dx, al

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

.not_ready:
    nop
    in al, dx
    and al, 0x88

    cmp al, 0x88
    jnz .not_ready

    mov ax, di
    mov dx, 256
    mul dx
    mov cx, ax

    mov dx, 0x1f0

.go_on_read:
    in ax, dx
    mov [bx], ax
    add bx, 2
    loop .go_on_read
    ret