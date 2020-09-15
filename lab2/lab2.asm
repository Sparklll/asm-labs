%include "lib.asm"

extern init_termios; @params: (rdi) - 0 - no echo mode, 1 - echo mode
extern reset_termios

section .data
BACKSPACE      equ 8
ENTER_BTN      equ 10
ESC_BTN        equ 27
SPACE_BTN      equ 32
BACKSPACE_BTN  equ 127



input_request1:         db 'Input a : ', 0
input_request2:         db 'Input b : ', 0
devision_result:        db 'Devision result (a:b) = ', 0
remainder:              db ', remainder ', 0
zero_devision_exception db 'Exception : zero devision!', 0

section .text
    global _start

_start:
    push r12
    push r13

    mov rdi, 0
    call init_termios


    mov rdi, input_request1
    call print_string
    call read_uint
    mov r12, rax

    mov rdi, input_request2
    call print_string
    call read_uint
    mov r13, rax

    cmp r13, 0
    je .zero_devision_exception

    xor rdx, rdx
    mov rax, r12
    div r13
    push rdx
    push rax
    
    mov rdi, devision_result
    call print_string

    pop rax
    mov rdi, rax
    call print_uint

    mov rdi, remainder
    call print_string
    
    pop rdx
    mov rdi, rdx
    call print_uint
    call print_newline
.end:
    pop r13
    pop r12
    call reset_termios
    exit
.zero_devision_exception:
    mov rdi, zero_devision_exception
    call print_string
    call print_newline
    jmp .end


read_uint:
    push rbx
    mov r8, 10
    xor rax, rax
    xor rbx, rbx;counting entered digits

.read_char:
    push rax
    call read_char
    mov r9, rax
    pop rax

    
    cmp r9, ENTER_BTN
    je .enter_handling
    cmp r9, BACKSPACE_BTN
    je .backspace_handling
    cmp r9, ESC_BTN
    je .esc_handling

    cmp r9, '0'
    jb .incorrect_input_handling
    cmp r9, '9'
    ja .incorrect_input_handling


.correct_input_handling:
    mov r10, r9
    sub r10, '0' ;integer representation of ASCII symbol
    mov r11, rax ;save (rax) for restore in case of overflow

    mul r8
    jc .overflow_handling
    add rax, r10
    jc .overflow_handling

    mov rdi, r9
    push rax
    call print_char
    pop rax
    inc rbx
    jmp .read_char

.overflow_handling:
    mov rax, r11 ;restore (rax)
    jmp .read_char

.enter_handling:
    cmp rbx, 0
    je .read_char

    push rax
    call print_newline
    pop rax
    jmp .end

.backspace_handling:
    cmp rbx, 0
    je .read_char

    push rax
    call remove_last_entered_char
    pop rax
    xor rdx, rdx
    div r8
    dec rbx
    jmp .read_char

.esc_handling:
    cmp rbx, 0
    je .read_char

.loop:
    call remove_last_entered_char
    dec rbx
    cmp rbx, 0
    jne .loop
    xor rax, rax
    jmp .read_char

.incorrect_input_handling:
    jmp .read_char

.end:
    pop rbx
    ret

remove_last_entered_char:
    mov rdi, BACKSPACE
    call print_char
    mov rdi, SPACE_BTN
    call print_char
    mov rdi, BACKSPACE
    call print_char
    ret
