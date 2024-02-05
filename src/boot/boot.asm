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
    mov eax, cr0 ; cr0 registers let's us change from real mode to protected mode
    or eax,0x1
    mov cr0,eax
    jmp CODE_SEG:load32
    
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
    jmp CODE_SEG:0x0100000 ; Jump to code segment after reading all sectors (Entry point of our kernel)

ata_lba_read:
    mov ebx,eax     ;Backup the LBA
    ;Send highest 8 bits (24-32) of the LBA to hard disk controller
    shr eax, 24     ; shift 24 bits to right
    or eax, 0xE0    ; Selecting  Master drive 
    mov dx, 0x1F6   ; Port where we have to send the highest 8 bits to
    out dx, al      ; As the bits are shifted 24 towards right,
                    ; The highest 8 bits are now in the lowest 8 bits of AX register
    
    ;Finished sending highest 8 bits of LBA

    ;Sending Total No. of sectors to the hard disk controller
    mov eax,ecx     ; Store the sectors to EBX register first
    mov dx, 0x1F2   ; Port to send the data to
    out dx, al      ; Send the data to the port
    ;Finished sending total No of sectors to the disk controller 

    ;Sending bits 0-7 of the LBA (Low 8 bits)
    mov eax, ebx    ; Restoring the backup LBA
    mov dx, 0x1F3   ; Port to send bit 0 - 7 of LBA
    out dx, al;
    ;Finished sending more bits to the disk controller

    ;Sending bits 8-15 of the LBA (Mid 8 bits)
    mov eax,ebx     ; Restoring the backup LBA
    mov dx, 0x1F4   ; Port to send the mid 8 bits
    shr eax, 8      ; shift 8 bits towards right to get mid 8 bits
    out dx, al      ; Sending the mid 8 bits to the port
    ;Finished sending Middle bits  of the LBA

    ;Sending bits 16-23 of the LBA (High 8 bits)
    mov eax, ebx
    mov dx, 0x1F5 ; Port to send bits 16-23
    shr eax, 16
    out dx, al
    ;Finished sending the High 8 bits 
    
    mov dx,0x1F7
    mov al, 0x20
    out dx, al

    ;Read all sectors in memory
.next_sector:
    push ecx ;Save register in stack to retrive the value later

    ;Checking if we need to read     
.try_again:
    mov dx, 0x1F7 ;Port used to send commands to the ATA device
    in al,dx
    test al, 8 ; ANDing the content of al register with 8 and setting up ZF flag accordingly
    jz .try_again ; if the result is a zero then try again

; We need to read 256 words at a time
    mov ecx,256     ; Putting value 256 in ecx
    mov dx, 0x1F0   ; Data port, I/O
    rep insw        ; Take 256 words i.e 512 bytes of data which means 1 sector
                    ; insw reads a word from I/O port and put into location specified in [ES:(E)DI]
                    ; [ES = 0 and EDI = 0x0100000] in our case so absolute address = [0x0100000]
    pop ecx; Restore the value (sector numbers)
    loop .next_sector ; Now loop and decremenet sector numbers, Basically, read all sectors upto 1 and when 0 return
    
    ;End of reading sectors into memory
    ret

times 510-($-$$) db 0
dw 0xAA55