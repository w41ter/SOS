%include "boot.inc"

SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

    mov eax, loader_start_sector
    mov bx, loader_base_address
    mov cx, 4
    call read_disk_m_16

    jmp loader_base_address + 0x300

read_disk_m_16:
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

times 510 - ($-$$) db 0
    db 0x55, 0xaa