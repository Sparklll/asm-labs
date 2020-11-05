%include "lib.asm"

extern time
extern srand
extern rand


section .data
    title:                 db "##--Tic-Tac-Toe--##", 10, 0
    instruction:           db "Enter the number of cell (1-9) to put X on : ", 0
    full_error:            db "Cannot put X on cell . because this cell is full.", 10, 0
    oob_error:             db "No such cell. Cells are numbered 1-9.", 10, 0
    win:                   db "You won! Restart? (y/n)", 10, 0
    fail:                  db "You failed! Restart? (y/n)", 10, 0
    tie:                   db "Tie! Restart? (y/n)", 10, 0
    escape:                db 27, "[2J", 27, "[1;1H", 0
    board_border_1:        db "   -   -   -  ", 10, 0
    board_border_2:        db " | . | . | . |", 10, 0
    board: times 9         db ' '
    full_error_is_visible: db 0  ; 0 - no, 1 - yes 
    oob_error_is_visible:  db 0  ; 0 - no, 1 - yes 
    game_status:           db 0  ; 0 - game on, 1 - failed, 2 - won, 3 - tied
    game_save_file         db "save", 0
    
section .bss
    input: resb 1
    dummy: resb 1


section .text
global _start

_start:
    ;system clear
    mov rdi, escape
    call print_string

    ;draw title
    mov rdi, title
    call print_string

    call draw_board

    ;check game status
    mov al, byte [game_status]
    cmp al, 1
    jl game_is_on
    je game_failed
    
    cmp al, 3
    jl game_won
    jmp game_tied


get_input_char:
    call read_char
    mov [input], al

    cmp byte [input], 10
    jne .L1
    ret

    .L1: ;read all the next chars from the stdin buffer untill meet '\n' (clear stdin buffer)
    call read_char
    mov [dummy], al

    cmp byte [dummy], 10
    jne .L1
    ret


save_game:
    ;@return: (rax) - file descriptor
    mov rax, SYS_OPEN
    mov rdi, game_save_file
    mov rsi, O_CREAT + O_WRONLY
    mov rdx, 0644o ;file permissions 
    syscall

    push rax
    mov rdi, rax
    mov rax, SYS_WRITE
    mov rsi, board
    mov rdx, 9
    syscall

    mov rax, SYS_CLOSE
    pop rdi
    syscall

    jmp _start

load_game:
    ;@return: (rax) - file descriptor
    mov rax, SYS_OPEN
    mov rdi, game_save_file
    mov rsi, O_RDONLY
    mov rdx, 0644o ;file permissions 
    syscall

    ;file exists?
	xor	rdx, rdx
	cmp	rax, rdx
	jle	_start

    push rax
    mov rdi, rax
    mov rax, SYS_READ
    mov rsi, board
    mov rdx, 9
    syscall

    mov rax, SYS_CLOSE
    pop rdi
    syscall

    jmp _start

draw_board:
    mov r8, board
    .L1:
    mov rdi, board_border_1
    call print_string

    mov rdi, board_border_2 ;

    mov dl, byte [r8]
    mov rsi, 3 ;[i][0]
    call edit_byte

    add r8, 1
    mov dl, byte [r8]
    mov rsi, 7 ;[i][1]
    call edit_byte

    add r8, 1
    mov dl, byte [r8]
    mov rsi, 11 ;[i][2]
    call edit_byte

    add r8, 1
    
    ;print game board line with inserted board_arr values
    mov rdi, board_border_2
    call print_string

    cmp r8, board+9
    jne .L1


    mov rdi, board_border_1
    call print_string
    call print_newline
    ret


clean_board:
    push rax
    mov rax, 0

    .loop:
    mov byte [board+rax], ' '
    inc rax
    cmp rax, 9
    jne .loop

    pop rax
    ret


;@params: (rdi) - i-th text field line ptr, (rsi) - offset, (dl) - new val
edit_byte:
    push rdi

    add rdi, rsi
    mov byte [rdi], dl

    pop rdi
    ret


game_is_on:
    ;print full_error?
    cmp byte [full_error_is_visible], 1
    jne .skip_full_error_logging ;skip full cell error msg

        ;edit full_error message byte
        mov dl, byte [input]
        mov rsi, 21
        mov rdi, full_error
        call edit_byte

        ;error msg
        mov rdi, full_error
        call print_string

    .skip_full_error_logging:

    ;print oobError?
    cmp byte [oob_error_is_visible], 1
    jne .skip_oob_error_logging ;skip oob_error msg

        ;error msg
        mov rdi, oob_error
        call print_string

    .skip_oob_error_logging:

    ;oev = 0, fev = 0
    mov byte [full_error_is_visible], 0
    mov byte [oob_error_is_visible], 0

    ;input instruction msg
    mov rdi, instruction
    call print_string

    ;fill 1-9 (cell) or save/load game
    call get_input_char

    ;save game board state to the file
    cmp byte [input], 's'
    je save_game

    ;load game board from previous save (if save file exists)
    cmp byte [input], 'l'
    je load_game


    ;i > 0?
    cmp byte [input], '1'
    jge .skip_oob_error_redirect1

        ; oob error!
        mov byte [oob_error_is_visible], 1
        jmp _start

    .skip_oob_error_redirect1:

    ;i < 10?
    cmp byte [input], '9'
    jle .skip_oob_error_redirect2

        ;oob error!
        mov byte [oob_error_is_visible], 1
        jmp _start

    .skip_oob_error_redirect2:


    ;board[input] = ' '?
    xor rax, rax
    mov al, byte [input]
    sub al, '1'
    mov rbx, board
    add rbx, rax
    mov al, byte [rbx]
    cmp al, ' '
    je .skip_full_error_redirect ;no full cell error

        ;full cell error!
        mov byte [full_error_is_visible], 1
        jmp _start

    .skip_full_error_redirect:

    ;enter the X
    mov byte [rbx], 'X'
    
    mov al, 'X'
    call is_game_over
    cmp ah, 0
    je .is_tie

        mov byte [game_status], 2
        jmp _start

    .is_tie:
    call are_any_moves_left

    cmp ah, 1
    je .cpu_move

        mov byte [game_status], 3
        jmp _start

    .cpu_move:
    call cpu_algorithm

    mov al, 'O'
    call is_game_over
    cmp ah, 0
    je .is_tie_again

        mov byte [game_status], 1
        jmp _start

    .is_tie_again:
    call are_any_moves_left

    cmp ah, 1
    je .not_tie

        mov byte [game_status], 3
        jmp _start

    .not_tie:
    jmp _start


;@params: (al) - expects side ('X' or 'O')
;@return: (ah) - 1 - yes, 0 -no
is_game_over:
    xor ah, ah
    push rbx

    mov bl, byte [board+0]
    cmp bl, al
    jne .step2

    mov bl, byte [board+3]
    cmp bl, al
    jne .step2
    
    mov bl, byte [board+6]
    cmp bl, al
    jne .step2
    jmp .yes

    .step2:
    mov bl, byte [board+1]
    cmp bl, al
    jne .step3

    mov bl, byte [board+4]
    cmp bl, al
    jne .step3
    
    mov bl, byte [board+7]
    cmp bl, al
    jne .step3
    jmp .yes

    .step3:
    mov bl, byte [board+2]
    cmp bl, al
    jne .step4

    mov bl, byte [board+5]
    cmp bl, al
    jne .step4
    
    mov bl, byte [board+8]
    cmp bl, al
    jne .step4
    jmp .yes

    .step4:
    mov bl, byte [board+0]
    cmp bl, al
    jne .step5

    mov bl, byte [board+1]
    cmp bl, al
    jne .step5
    
    mov bl, byte [board+2]
    cmp bl, al
    jne .step5
    jmp .yes

    .step5:
    mov bl, byte [board+3]
    cmp bl, al
    jne .step6

    mov bl, byte [board+4]
    cmp bl, al
    jne .step6
    
    mov bl, byte [board+5]
    cmp bl, al
    jne .step6
    jmp .yes

    .step6:
    mov bl, byte [board+6]
    cmp bl, al
    jne .step7

    mov bl, byte [board+7]
    cmp bl, al
    jne .step7
    
    mov bl, byte [board+8]
    cmp bl, al
    jne .step7
    jmp .yes

    .step7:
    mov bl, byte [board+0]
    cmp bl, al
    jne .step8

    mov bl, byte [board+4]
    cmp bl, al
    jne .step8
    
    mov bl, byte [board+8]
    cmp bl, al
    jne .step8
    jmp .yes

    .step8:
    mov bl, byte [board+2]
    cmp bl, al
    jne .no

    mov bl, byte [board+4]
    cmp bl, al
    jne .no
    
    mov bl, byte [board+6]
    cmp bl, al
    jne .no
    jmp .yes

    .no:
    mov ah, 0
    pop rbx
    ret

    .yes:
    mov ah, 1
    pop rbx
    ret


;@returns (ah) : 1 = yes, 0 = no.
are_any_moves_left:
    mov rax, board

    .loop:
    cmp byte [rax], ' '
    je .yes
    inc rax

    cmp rax, board+9
    jne .loop
    jmp .no

    .no:
    mov ah, 0
    ret

    .yes:
    mov ah, 1
    ret


game_failed:
    mov rdi, fail
    call print_string

    call game_restart_decision


game_won:
    mov rdi, win
    call print_string

    call game_restart_decision


game_tied:
    mov rdi, tie
    call print_string

    call game_restart_decision


game_restart_decision:
    call get_input_char
    cmp byte [input], 'y'
    jne end
    mov byte [game_status], 0
    call clean_board
    jmp _start


cpu_algorithm:
    mov rcx, 0

    .loop1:

    cmp rcx, 9
    je .no_winning_positions

    cmp byte [board+rcx], ' '
    je .cell_is_empty
    jne .cell_is_full

    .cell_is_full:
    inc rcx
    jmp .loop1

    .cell_is_empty:
    mov byte [board+rcx], 'O'
    mov al, 'O'
    call is_game_over
    cmp ah, 1
    jne .not_winning_position
    ret

    .not_winning_position:
    mov byte [board+ecx], ' '
    inc rcx

    jmp .loop1

    .no_winning_positions:

    xor rcx, rcx
    
    .loop2:
    cmp rcx, 9
    je .move_randomly

    cmp byte [board+rcx], ' '
    je .cell_is_empty2
    inc rcx
    jmp .loop2

    .cell_is_empty2:
    mov byte [board+rcx], 'X'
    mov al, 'X'
    call is_game_over
    cmp ah, 1
    je .prevent_win
    
    mov byte [board+ecx], ' '
    inc rcx
    jmp .loop2

    .prevent_win:
    mov byte [board+rcx], 'O'
    ret
    
    .move_randomly:

    ;set seed srand(time(0))
    mov rdi, 0
    call time
    mov rdi, rax
    call srand

    .loop3:
    ;offset = rand() / ( 2^64 / 9 )
    call rand
    mov rbx, 9
    xor rdx, rdx
    cqo
    div rbx

    cmp byte [board+rdx], ' '
    jne .loop3

    mov byte [board+rdx], 'O'
    ret
       
end:  
    exit