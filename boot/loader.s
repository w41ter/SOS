%include "boot.inc"
section loader vstart=loader_base_address
    mov byte [gs:0x00], 'L'
    mov byte [gs:0x01], 0xa4

    mov byte [gs:0x02], 'o'
    mov byte [gs:0x03], 0xa4

    mov byte [gs:0x04], 'a'
    mov byte [gs:0x05], 0xa4

    mov byte [gs:0x06], 'd'
    mov byte [gs:0x07], 0xa4

    mov byte [gs:0x08], 'e'
    mov byte [gs:0x09], 0xa4

    mov byte [gs:0x0a], 'r'
    mov byte [gs:0x0b], 0xa4

    jmp $