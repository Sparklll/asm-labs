%include "lib.asm"

section .data
buffer_length    equ 256
input_request1:  db 'Enter a line of text : ', 0
input_request2:  db 'Enter a substring pattern to search in text line : ', 0
conclusion_yes:  db 'The text contains occurrence of the entered substring at index ', 0
conclusion_no:   db 'The text doesnt contain occurrence of the entered substring.', 0

section .bss
text:       resb buffer_length
pattern:    resb buffer_length
lps_array:  resb buffer_length


section .text
    global _start

_start:
    push r12
    push r13

    ;request/read text line
    mov rdi, input_request1
    call print_string

    mov rdi, text
    mov rsi, buffer_length
    call read_word
    mov r12, rdx ;text_length

    ;request/read pattern line
    mov rdi, input_request2
    call print_string

    mov rdi, pattern
    mov rsi, buffer_length
    call read_word
    mov r13, rdx ;pattern_length


    ;compute prefix fucntion for entered 'pattern' and call kmp_search
    mov rdi, r13
    call prefix_function

    mov rdi, r12
    mov rsi, r13
    call kmp_search


    pop r13
    pop r12
    exit


;@params: (rdi) - text_length, (rsi) - pattern_length
kmp_search:
    mov r10, rdi ;text_length
    mov r11, rsi ;pattern_length
    mov r8, 0    ;text_index
    mov r9, 0    ;pattern_index

.while_begin:
    cmp r8, r10
    jae .end_with_conslution_no

    mov bl, [text + r8]
    mov cl, [pattern + r9] 
    cmp bl, cl
    jne .textIndex_equals_textSize

    inc r8
    inc r9

.textIndex_equals_textSize:
    cmp r9, r11
    jne .check_mismatch
    mov rax, r8
    sub rax, r9

    push rax
    mov rdi, conclusion_yes
    call print_string
    pop rax 
    
    push r8
    mov rdi, rax    
    call print_uint
    pop r8

    call print_newline

    jmp .while_end

.check_mismatch:
    cmp r8, r10
    jb .continue1
    jmp .end_with_conslution_no
.continue1:
    mov bl, [text + r8]
    mov cl, [pattern + r9] 
    cmp bl, cl
    jne .continue2
    jmp .while_begin
.continue2:
    cmp r9, 0
    je .patt_index_equals_zero

    mov r9b, [lps_array + r9 - 1]
    jmp .while_begin

.patt_index_equals_zero:
    inc r8
    jmp .while_begin

.while_end:
    ret

.end_with_conslution_no:
    mov rdi, conclusion_no
    call print_string
    call print_newline
    jmp .while_end




;@params: (rdi) - pattern_length
;@return: filled lps_array (calculated prefix function for each char of pattern)
prefix_function:
    mov byte [lps_array], 0 ;prefix fucntion of first char is always 0
    mov r8, 0 ;holds the length of the previous prefix which is also suffix
    mov r9, 1 ;counter (i)

.while_begin:
    cmp r9, rdi
    jae .while_end
    
    mov r10b, [pattern + r8]
    mov r11b, [pattern + r9] 
    cmp r10b, r11b
    jne .chars_not_equal

    inc r8
    mov [lps_array + r9], r8b
    inc r9
    jmp .while_begin

.chars_not_equal:
    cmp r8, 0
    je .length_is_zero
    mov r8b, [lps_array + r8 - 1]

    jmp .while_begin

.length_is_zero:
    mov byte [lps_array + r9], 0
    inc r9

    jmp .while_begin
.while_end:
    ret