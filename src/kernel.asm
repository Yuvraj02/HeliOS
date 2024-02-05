[BITS 32]
global _start

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax,DATA_SEG
    mov ds,ax
    mov es,ax
    mov gs,ax
    mov fs,ax
    mov ss,ax
    mov ebp,0x00200000 ; avoids conflicting with system-specific memory regions, that's why this memory location is chosen for protected mode 
    mov esp, ebp  

    ;Enabling A20 line
    in al,0x92
    or al,2
    out 0x92,al
    jmp $