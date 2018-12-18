;  Executable name : hexdump3
;  Version         : 1.0
;  Created date    : 18 Dec 2018
;  Last updated    : 18 Dec 2018
;  Author          : Brian Hart
;  Description     : A simple hex dump utility demonstrating the use of
;                    separately assembled code libraries via EXTERN
;
;  Build using these commands:
;    nasm -f elf64 -g -F stabs hexdump3.asm
;    ld -o hexdump3 hexdump3.o <path>/textlib.o
;
; This code is from the book "Assembly Language Step by Step: Programming with Linux," 3rd ed.,
; by Jeff Duntemann (John Wiley & Sons, 2009).
;
; The following are equates that define named constants, for enhanced program readability
;
BUFFLEN     EQU 10                  ; Length of buffer, in bytes

SYS_EXIT    EQU 1                   ; Syscall number for sys_exit
SYS_READ    EQU 3                   ; Syscall number for sys_read
SYS_WRITE   EQU 4                   ; Syscall number for sys_write

OK          EQU 0                   ; Operation completed without errors
ERROR       EQU -1                  ; Operation failed to complete; error flag

STDIN       EQU 0                   ; File Descriptor 0: Standard Input
STDOUT      EQU 1                   ; File Descriptor 1: Standard Output
STDERR      EQU 2                   ; File Descriptor 2: Standard Error

EOF         EQU 0                   ; End-of-file reached

SECTION     .bss                        ; Uninitialized data
        Buff    resb    BUFFLEN         ; Text buffer
        
SECTION     .data                       ; Section containing initialized data


SECTION     .text                       ; Section containing code
      
EXTERN      ClearLine,  DumpChar,   PrintLine

GLOBAL      _start


_start:
        nop                             ; This no-op keeps gdb happy...
        nop
        xor esi, esi                    ; Clear total chars counter to 0
        
; Read a buffer-full of text from stdin:
Read:
        mov eax, SYS_READ               ; Specify sys_read call
        mov ebx, STDIN                  ; Specify File Descriptor 0: Standard Input
        mov ecx, Buff                   ; Pass offset of the bufffer to read to
        mov edx, BUFFLEN                ; Pass number of bytes to read at one pass
        int 80h                         ; Call sys_read to fill the buffer
        mov ebp, eax                    ; Save # of bytes read from file for later
        cmp eax, EOF                    ; If eax=0, sys_read reached EOF on stdin
        je  Done                        ; Jump If Equal (to 0, from Compare)
        
; Set up the registers for the process buffer step:
        xor ecx, ecx                    ; Clear buffer pointer to 0
        
; Go through the buffer and convert binary values to hex digits:
Scan:
        xor eax, eax                    ; Clear EAX to 0
        mov al, BYTE [Buff+ecx]         ; Get a char from the buffer into AL
        mov edx, esi                    ; Copy total counter into EDX
        and edx, 0000000Fh              ; Mask out lowest 4 bits of char counter, since this
                                        ; lowest nybble rolls over and over from 0 to 15 and thus
                                        ; gives the poke position into the "dump line"
        call DumpChar                   ; Call the char poke procedure
        
; Bump the buffer pointer to the next character and see if buffer's done:
        inc ecx                         ; Increment buffer pointer
        inc esi                         ; Increment total chars processed counter
        cmp ecx, ebp                    ; Compare with # of chars in buffer
        jae Read                        ; If we've done the buffer, go get more
        
; See if we're at the end of a block of 16 and need to display a line:
        test esi, 0000000Fh             ; Test 4 lowest bits in the total-character counter for zero
        jnz  Scan                       ; If this is not the case, more chars to process
        call PrintLine                  ; ... otherwise print the line
        call ClearLine                  ; Clear hex dump line to 0's
        jmp  Scan                       ; Continue scanning the buffer
        
 ; All done!  Let's end this party:
 Done:
        call PrintLine                  ; Print the "leftovers" line
        mov  eax, SYS_EXIT              ; Code for Exit Syscall
        mov  ebx, OK                    ; Return a code of zero
        int  80h                        ; Make kernel call