%include "lib.asm"

section .data
a: dq 1
b: dq 2
c: dq 3
d: dq 4

section .text
    global _start

_start:
    call calc_function
    exit


calc_function:
    push rbx
    mov rax, [a]
    add rax, [b]
    mov rbx, [c]
    or  rbx, [d]
    cmp rax, rbx
    je .cond1_true

    mov rax, [b]
    xor rax, [c]
    mov rbx, [a]
    or  rbx, [d]
    cmp rax, rbx
    je .cond2_true

    mov rax, [a]
    xor rax, [b]
    mov rbx, [c]
    xor rbx, [d]
    or  rax, rbx
    mov rdi, rax
    call print_uint
    call print_newline
    jmp .end

.cond1_true:
    mov rbx, [c]
    xor rbx, [d]
    and rax, rbx
    mov rdi, rax
    call print_uint
    call print_newline
    jmp .end
.cond2_true:
    and rax, rbx
    mov rdi, rax
    call print_uint
    call print_newline
    jmp .end

.end:
    pop rbx
    ret