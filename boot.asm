ORG 0

BITS 16

_start:
    jmp short main ;  2 byte
    nop            ; +1 byte 

times 33 db 0

main:
    jmp 0x7c0:start ; Setting CS with 0x7c0

start:
    cli ; Clear Interrupts
    mov ax, 0x7c0 ; Because we can't assign immediates to DS, so first assign to a register 'ax'
    mov ds,ax 
    mov es,ax
    mov ax,0x00
    mov ss,ax
    mov sp,0x7c00
    sti ; Enables Interrupts
    
    mov ah, 0x02 ;Reading into memory
    mov al, 1 ; read just 1 sector
    mov ch, 0 ; starting of the cylinder (low eight bits)
    mov cl, 2 ; read sector 2
    mov dh, 0 ; head number, this is the first r/w head which we wants to use 
    mov bx, buffer
    int 0x13
    jc error ; if carry flag is set, then jump to label error
    
    mov si, buffer ;set si to buffer
    call print ; print the buffer
    jmp $ 

error:
    mov si, error_message
    call print
    jmp $

print:
    lodsb
    cmp al,0
    je .done
    call print_char
    jmp print

.done:
    ret

print_char:
    mov ah,0eh
    int 0x10
    ret

error_message : db 'Failed to load sector', 0

times 510-($-$$) db 0
dw 0xAA55

buffer:  ;Anything other than sector 1 (boot sector) can be referenced using this empty label