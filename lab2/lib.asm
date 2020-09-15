section .data

;file descriptors
STDIN   equ 0
STDOUT  equ 1
STDERR  equ 2

;system calls
SYS_READ    equ 0
SYS_WRITE   equ 1
SYS_OPEN    equ 2
SYS_CLOSE   equ 3
SYS_EXIT    equ 60

section .text

%macro exit 0
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
%endmacro

;@params: (rdi) - ptr to null terminated str
;@return: (rax) - str_length
string_length:
    xor rax, rax
.loop:
    cmp byte[rdi+rax], 0
    je .end
    inc rax
    jmp .loop
.end:
    ret

;@params: (rdi) - ptr to null terminated str
print_string:
    call string_length
    mov rdx, rax
    mov rsi, rdi
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    syscall
    ret

;@params: (rdi) - char's ascii code
print_char:
    push rdi
    mov rdi, rsp
    call print_string 
    pop rdi
    ret

print_newline:
    mov rdi, 10
    call print_char
    ret

;@params: (rdi) - unsigned number
print_uint:
    mov rax, rdi
    mov rdi, rsp
    push 0
    sub rsp, 16
    
    dec rdi
    mov r8, 10
    
.loop:
    xor rdx, rdx
    div r8
    or  dl, 0x30 ;add '0'
    dec rdi 
    mov [rdi], dl
    test rax, rax
    jnz .loop 
   
    call print_string
    
    add rsp, 24
    ret

;@params: (rdi) - signed or unsigned number
print_int:
    test rdi, rdi
    jns print_uint
    push rdi
    mov rdi, '-'
    call print_char
    pop rdi
    neg rdi
    call print_uint
    ret

;@return: (rax) - char_ptr
read_char:
    push 0
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, rsp
    mov rdx, 1
    syscall
    pop rax
    ret 

;@params: (rdi) - buffer_ptr, (rsi) - buffer_size
;@return: (rax) - buffer address
;otherwise if word is too big 0, (rdx) - word length 
read_word:
    push r12
    push r13
    xor r12, r12 
    mov r13, rsi
    dec r13

;remove front blankspaces, \t  \n, \r, 
.A:
    push rdi
    call read_char
    pop rdi
    cmp al, ' '
    je .A 
    cmp al, 9 
    je .A
    cmp al, 10
    je .A
    cmp al, 13
    je .A
    test al, al
    jz .C

.B:
    mov byte [rdi + r12], al
    inc r12

    push rdi
    call read_char
    pop rdi
    cmp al, ' '
    je .C
    cmp al, 9
    je .C
    cmp al, 10
    je .C
    cmp al, 13
    je .C 
    test al, al
    jz .C
    cmp r12, r13
    je .D

    jmp .B

.C:
    mov byte [rdi + r12], 0
    mov rax, rdi 
   
    mov rdx, r12 
    pop r13
    pop r12
    ret

;buffer overflow
.D:
    xor rax, rax
    pop r13
    pop r12
    ret

;@params: (rdi) - ptr to null terminated str
;@return: (rax) - number, (rdx) - number_length
parse_uint:
    mov r8, 10
    xor rax, rax
    xor rcx, rcx
.loop:
    movzx r9, byte [rdi + rcx] 

    cmp r9b, '0'
    jb .end
    cmp r9b, '9'
    ja .end
    
    xor rdx, rdx 
    mul r8
    and r9b, 0x0f
    add rax, r9
    inc rcx 
    jmp .loop 
.end:
    mov rdx, rcx
    ret

;@params: (rdi) - ptr to null terminated str
;@return: (rax) - number, (rdx) - number_length
parse_int:
    mov al, byte [rdi]
    cmp al, '-'
    je .signed
    jmp parse_uint
.signed:
    inc rdi
    call parse_uint
    neg rax
    test rdx, rdx
    jz .error

    inc rdx
    ret
.error:
    xor rax, rax
    ret 

;@params: (rdi) - ptr to 1st null terminated str,
;(rsi) - ptr to 2nd null terminated str
;@return: 1 - equals, 0 - not
string_equals:
    mov al, [rdi]
    cmp al, [rsi]
    jne .no
    inc rdi
    inc rsi
    test al, al
    jnz string_equals
    mov rax, 1
    jmp .end
.no:
    xor rax, rax
    jmp .end
.end:
    ret

;@params: (rdi) - str_ptr, (rsi) - buffer_ptr
;(rdx) - buffer_size
;@return: (rax) - destination address
;if string fits the buffer otherwise 0
string_copy:
    ret