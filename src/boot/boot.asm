ORG 0x7c00

BITS 16

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short main ;  2 byte
    nop            ; +1 byte 
                   ; we skip 3 bytes as they contain information regarding the storage device, or process might overwrite the data which is not code
                   ; hence it is neccessary to skip 3 bytes and fill 33 bytes with null values, so even if BIOS writes something in this area, it
                   ; won't affect our code

                   ; Check Documentation about BPB on OSDev Wiki
times 33 db 0      ; Fill rest of the bytes with null values and skip BPB

main:
    jmp 0:start ; Setting CS with 0x7c0

start:
    cli ; Clear Interrupts
    mov ax, 0x00 ; Because we can't assign immediates to DS, so first assign to a register 'ax'
    mov ds,ax 
    mov es,ax
    mov ss,ax
    mov sp,0x7c00
    sti ; Enables Interrupts

load_protectd:
    cli
    lgdt[gdt_descriptor]
    mov eax, cr0
    or eax,0x1
    mov cr0,eax
    ;jmp CODE_SEG:load32
    jmp $
gdt_start:
gdt_null: ;Set 64 bits to null
    dd 0x0 ; 32-bit
    dd 0x0 ; 32bit

; offset 0x08
gdt_code:        ; CS should point to this
    dw 0xffff    ; Defining segment limit first 0-15 bits
    dw 0         ; Base first 0-15 bits
    db 0         ; Base 16-23 bits
    db 0x9a      ; Setting access byte to 0x9a which means this segment (code segment) is readable and writeable
    db 11001111b ; Setting left 4 bits for additional flags and right 4 bits for high bits of segment 'limit'  
    db 0         ; base 24-31

; offset 0x10
gdt_data:        ; CS should point to this
    dw 0xffff    ; Defining segment limit first 0-15 bits
    dw 0         ; Base first 0-15 bits
    db 0         ; Base 16-23 bits
    db 0x92      ; Setting access byte to 0x92 which means this segment (segment) is in previlge mode and non-writable
    db 11001111b ; Setting left 4 bits for additional flags and right 4 bits for high bits of segment 'limit'  
    db 0         ; base 24-31

gdt_end:

gdt_descriptor:
    dw gdt_end-gdt_start-1 ; size of descriptor
    dd gdt_start

[BITS 32]
load32:
    mov eax, 1      ; Representing starting sector, not 0, because it's the boot sector, so 1
    mov ecx, 100    ; Total sectors
    mov edi, 0x0100000 ;Address where we want to load the sectors
    call ata_lba_read ;

ata_lba_read:
    mov ebx,eax  ;Backup the LBA
    ;Send highest 8 bits of the lba to hard disk controller
    shr eax, 24  ;shift 24 bits to right

times 510-($-$$) db 0
dw 0xAA55