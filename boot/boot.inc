; loader and kernel
loader_base_address equ 0x900
loader_start_sector equ 0x2

; gdt descriptor
desc_g_4k        equ 0x800000   ; 1000_0000_0000_0000_0000_0000b
desc_g_1         equ 0x0        ; 0000_0000_0000_0000_0000_0000b
desc_d_32        equ 0x400000   ; 0100_0000_0000_0000_0000_0000b
desc_l           equ 0x0        ; 0000_0000_0000_0000_0000_0000b
desc_avl         equ 0x0        ; 0000_0000_0000_0000_0000_0000b

desc_limit_code2 equ  0xf0000   ; 1111_0000_0000_0000_0000b
desc_limit_data2 equ  0xf0000
desc_limit_video2 equ  0x00000

desc_p           equ  0x8000    ; 1000_0000_0000_0000b
desc_dpl_0       equ  0x0000    ; 0000_0000_0000_0000b
desc_dpl_1       equ  0x2000    ; 0010_0000_0000_0000b
desc_dpl_2       equ  0x4000    ; 0100_0000_0000_0000b
desc_dpl_3       equ  0x6000    ; 0110_0000_0000_0000b

desc_s_code      equ  0x1000    ; 0001_0000_0000_0000b
desc_s_data      equ  0x1000    ; 0001_0000_0000_0000b
desc_s_sys       equ  0x0000    ; 0000_0000_0000_0000b

; x=1, c=0, r=0, a=0
desc_type_code   equ  0x800     ; 1000_0000_0000b
; x=0, e=0, w=1, a=0
desc_type_data   equ  0x200     ; 0010_0000_0000b

desc_code_high4  equ  ((0x00 << 24) + desc_g_4k + desc_d_32 \
                        + desc_l + desc_avl + desc_limit_code2 \
                        + desc_p + desc_dpl_0 + desc_s_code \
                        + desc_type_code + 0x00)

desc_data_high4  equ  ((0x00 << 24) + desc_g_4k + desc_d_32 \
                        + desc_l + desc_avl + desc_limit_data2 \
                        + desc_p + desc_dpl_0 + desc_s_data \
                        + desc_type_data + 0x00)

desc_video_high4 equ  ((0x00 << 24) + desc_g_4k + desc_d_32 \
                        + desc_l + desc_avl + desc_limit_video2 \
                        + desc_p + desc_dpl_0 + desc_s_data \
                        + desc_type_data + 0x00)

; selector
RPL0 equ 00b
RPL1 equ 01b;
RPL2 equ 10b;
RPL3 equ 11b;

TI_GDT equ 000b
TI_LDT equ 100b