org 100h

; 
; CONSTANTS
;
MAX_WORDS = 128
WORD_LEN  = 5
TRIES     = 6
GREEN     = 0Ah
YELLOW    = 0Eh
GRAY      = 07h

; 
; CODE
; 
jmp start

; 
; DATA
;
filename    db "words.txt",0
fileHandle  dw 0
wordCount   dw 0
words db MAX_WORDS * 7 dup(0)

secretWord  db 5 dup(0)
guess       db 6 dup(0)
msgPrompt   db "Enter a 5-letter word: $"
msgInvalid  db 13,10,"Invalid word!",13,10,"$"
msgWin      db 13,10,"You WIN!",13,10,"$"
msgLose     db 13,10,"You LOSE! Secret: $"
triesLeft   db TRIES
newline     db 13,10,"$"
msgDebug    db "First word loaded: $"
msgWordCount db "Words loaded: $"           
msgTries db "Tries left: $"


;
; MAIN PROGRAM
; 
start:
    call load_words
    ;call debug_display
    call select_secret
    
game_loop:
    mov al,triesLeft
    cmp al,0
    je lose
    call get_input
    call validate_word
    jc invalid
    call check_guess   
    call display_tries
    mov al,triesLeft
    dec al
    mov triesLeft,al
    jmp game_loop
    
invalid:
    mov dx,offset msgInvalid
    mov ah,09h
    int 21h
    jmp game_loop
    
win:
    mov dx,offset msgWin
    mov ah,09h
    int 21h
    jmp exit
    
lose:
    mov dx,offset msgLose
    mov ah,09h
    int 21h
    mov si,offset secretWord
    mov cx,5
show_secret:
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    loop show_secret
    mov dx,offset newline
    mov ah,09h
    int 21h
    
exit:
    mov ah,4Ch
    int 21h

load_words:
    mov ah,3Dh
    mov al,0
    mov dx,offset filename
    int 21h
    jc load_error

    mov fileHandle,ax
    mov si,offset words
    mov wordCount,0


read_loop:
    mov ah,3Fh
    mov bx,fileHandle
    mov cx,7
    mov dx,si
    int 21h

    cmp ax,7
    jne done_read   
    push si
    mov cx,5
uppercase_loop:
    mov al,[si]
    cmp al,'a'
    jb skip_convert
    cmp al,'z'
    ja skip_convert
    sub al,32
    mov [si],al
skip_convert:
    inc si
    loop uppercase_loop
    pop si

    add si,7

    mov ax,wordCount
    inc ax
    mov wordCount,ax
    cmp ax,MAX_WORDS
    jae done_read

    jmp read_loop

done_read:
    mov ah,3Eh
    mov bx,fileHandle
    int 21h

load_error:
    ret


; 
; SELECT SECRET WORD
;
select_secret:
    ;
    mov ah,00h      
    int 1Ah          
    mov ax,dx
    mov bx, wordCount  
    xor dx, dx         
    div bx            
                      
    mov si, dx         
    mov di, offset secretWord
    mov bx, si
    mov si, offset words
    mov ax, bx
    mov cx, 7
    mul cx             
    add si, ax        

    mov cx, 5         
copy_loop:
    mov al, [si]
    mov [di], al
    inc si
    inc di
    loop copy_loop
    ret


; 
; GET USER INPUT 
; 
get_input:
    mov dx,offset msgPrompt
    mov ah,09h
    int 21h
    
    mov si,offset guess
    mov cx,0               
    
read_char:
    mov ah,08h              
    int 21h
    
    cmp al,13               
    je check_complete
    
    cmp al,8                
    je handle_backspace
    
    
    cmp cx,5
    jae read_char           
    
   
    cmp al,'A'
    jb read_char
    cmp al,'Z'
    jbe store_upper
    cmp al,'a'
    jb read_char
    cmp al,'z'
    ja read_char
    
    
    sub al,32
    
store_upper:
    
    push ax
    mov dl,al
    mov ah,02h
    int 21h
    pop ax
    
    
    mov [si],al
    inc si
    inc cx
    jmp read_char
    
handle_backspace:
    cmp cx,0                
    je read_char            
    
   
    dec si
    dec cx
    
   
    mov ah,02h
    mov dl,8               
    int 21h
    mov dl,' '              
    int 21h
    mov dl,8                
    int 21h
    
    jmp read_char
    
check_complete:
    cmp cx,5                
    jne read_char           
    
   
    mov ah,02h
    mov dl,13
    int 21h
    mov dl,10
    int 21h
    ret

validate_word:
    mov bx,0
    mov si,offset words

next_word:
    mov ax,wordCount
    cmp bx,ax
    je invalid_word

    push si
    mov di,offset guess
    mov cx,5

compare_loop:
    mov al,[si]
    mov ah,[di]
    cmp al,ah
    jne not_equal
    inc si
    inc di
    loop compare_loop

    pop si
    clc
    ret

not_equal:
    pop si
    add si,7       
    inc bx
    jmp next_word

invalid_word:
    stc
    ret

; 
; CHECK GUESS
; 
check_guess:
    mov si,offset guess
    mov di,offset secretWord
    mov cx,5
    
check_loop:
    push cx
    push si
    push di
    
    mov al,[si]
    mov ah,[di]
    
    cmp al,ah
    je is_green
    
    ; Scan secret word for yellow
    mov bx,offset secretWord
    push cx
    mov cx,5
    
scan_loop:
    mov ah,[bx]
    cmp al,ah
    je is_yellow
    inc bx
    dec cx
    cmp cx,0
    jne scan_loop
    pop cx
    
    ; gray
    mov bl,GRAY
    jmp print_letter
    
is_green:
    mov bl,GREEN
    jmp print_letter
    
is_yellow:
    pop cx
    mov bl,YELLOW
    
print_letter:
    pop di
    pop si
    mov al,[si]
    
    ; Write character with color
    mov ah,09h
    mov bh,0
    push cx
    mov cx,1
    int 10h
    pop cx
    
    ; Move cursor
    mov ah,03h
    mov bh,0
    int 10h
    inc dl 
    
    mov ah,02h
    int 10h
    
    inc si
    inc di
    pop cx
    dec cx
    cmp cx,0
    jne check_loop
    
    ; Newline
    mov ah,02h
    mov dl,13
    int 21h
    mov dl,10
    int 21h
    
    ; Check win
    mov si,offset guess
    mov di,offset secretWord
    mov cx,5
    
win_check:
    mov al,[si]
    mov ah,[di]
    cmp al,ah
    jne not_win
    inc si
    inc di
    dec cx
    cmp cx,0
    jne win_check
    jmp win
    
not_win:
    ret

; 
; DEBUG DISPLAY
; 
display_tries:
    mov dx, offset msgTries
    mov ah, 09h
    int 21h

    mov al, triesLeft     ; get remaining tries
    mov ah, 0
    mov ax, 0             ; clear AX 
    mov al, triesLeft
    call print_number     

    
    mov dx, offset newline
    mov ah, 09h
    int 21h
    ret

debug_display:
    ; Show word count
    mov dx,offset msgWordCount
    mov ah,09h
    int 21h

    mov ax,wordCount
    call print_number

    mov dx,offset newline
    mov ah,09h
    int 21h

    ; Print all words
    mov bx,0                  ; word index
    mov si,offset words

next_debug_word:
    mov ax,wordCount
    cmp bx,ax
    jae debug_done

    ; print 5 letters
    mov cx,5
print_letters:
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    dec cx
    cmp cx,0
    jne print_letters

    ; newline
    mov dx,offset newline
    mov ah,09h
    int 21h

    ; skip CR/LF
    add si,2

    inc bx
    jmp next_debug_word

debug_done:
    ret

; 
; PRINT NUMBER (AX)
; 
print_number:
    push ax
    push bx
    push cx
    push dx
    
    mov cx,0
    mov bx,10
    
divide_loop:
    mov dx,0
    div bx
    push dx
    inc cx
    cmp ax,0
    jne divide_loop
    
print_digits:
    pop dx
    add dl,'0'
    mov ah,02h
    int 21h
    dec cx
    cmp cx,0
    jne print_digits
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret