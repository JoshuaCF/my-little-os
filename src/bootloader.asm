	org 0x7C00
; enforce CS:IP
	jmp 0x0000:start

; set up a stack
; current setup allows 4KiB of stack space
stack_start: equ 0x1000
	mov ax, 0
	mov ss, ax
	mov sp, stack_start

; set up cursor
start:
	mov ah, 0x01
	mov ch, 0x00
	mov cl, 0x0F
	int 0x10

; clear display
	mov cl, 0
clear_loop:
	mov ah, 0x0E
	mov al, 10
	mov bh, 0
	mov bl, 0
	int 0x10

	inc cl
	cmp cl, 60
	jb clear_loop

	mov di, sp
	sub sp, 6
loop:
; set cursor position
; prompt for op
	mov bp, prompt
	mov cx, prompt_len
	call write_str
	call get_line ; len returned in ax
	push ax
	call write_lf
	pop ax
	call parse_op
	mov [di-2], ax

; prompt for num1
	mov bp, num_prompt
	mov cx, num_prompt_len
	call write_str
	call get_line
	push ax
	call write_lf
	pop ax
	call parse_num
	mov [di-4], ax

; prompt for num2
	mov bp, num_prompt
	mov cx, num_prompt_len
	call write_str
	call get_line
	push ax
	call write_lf
	pop ax
	call parse_num
	mov [di-6], ax

; eval, print, loop
	mov al, [di-2]
	.add:
	cmp al, 0
	jne .sub
	mov al, [di-4]
	add al, [di-6]
	jmp .print_result

	.sub:
	cmp al, 1
	jne .mul
	mov al, [di-4]
	sub al, [di-6]
	jmp .print_result

	.mul:
	cmp al, 2
	jne .div
	mov al, [di-4]
	mul byte [di-6]
	jmp .print_result

	.div:
	mov al, [di-4]
	div byte [di-6]
	xor ah, ah
	jmp .print_result

	.print_result:
	mov ah, 0
	call stringify_num
	mov bp, in_bfr
	add bp, ax
	mov cx, 16
	sub cx, ax
	call write_str
	call write_lf

	jmp loop

; ax = in_bfr len
; returns in ax
; 0 = add
; 1 = sub
; 2 = mul
; 3 = div
parse_op:
	mov al, [in_bfr]

	.add:
	cmp al, '+'
	jne .sub
	mov ax, 0
	ret

	.sub:
	cmp al, '-'
	jne .mul
	mov ax, 1
	ret

	.mul:
	cmp al, '*'
	jne .div
	mov ax, 2
	ret

	.div:
	mov ax, 3
	ret

; ax = in_bfr len
; return in ax
; clobbers si, bx, cx, dx
parse_num:
	mov si, ax
	mov bl, 10
	mov dx, 0
	mov cl, 1
	.loop:
	dec si
	mov al, [in_bfr+si]
	sub al, '0'
	mul cl
	add dx, ax
	mov al, cl
	mul bl
	mov cx, ax
	cmp si, 0
	ja .loop
	mov ax, dx
	ret

; al = num to encode
; returns start pos in ax
; reusing in_bfr because why not
stringify_num:
	mov bl, 10
	mov si, 16
	dec si
	mov byte [in_bfr + si], `\r`
	.loop:
	dec si
	div bl
	add ah, '0'
	mov [in_bfr + si], ah
	xor ah, ah
	cmp al, 0
	jne .loop
	mov ax, si
	ret

get_line: ; clobbers ax, bx, si, return len in ax
	mov si, 0
	.loop:
	call get_with_echo
	mov [in_bfr + si], al
	cmp al, `\r`
	je .exit
	inc si
	jmp .loop
	
	.exit:
	mov ax, si
	ret

write_lf: ; clobbers ax, bx
	mov al, `\n`
	call write_char
	ret

get_with_echo: ; clobbers ax, bx, returns char in al
	mov ah, 0x00
	int 0x16
	call write_char
	ret

write_char: ; al = char, clobbers ah, bx
	mov ah, 0x0E
	mov bx, 0
	int 0x10
	ret

write_str: ; bp = ptr, cx = num bytes, clobbers ax, bx, si
	mov si, 0
	.loop:
	mov al, [bp + si]
	call write_char
	inc si
	cmp si, cx
	jb .loop
	ret

in_bfr:
	times 16 db 0
prompt:
	db "Op:", 13, 10
prompt_len: equ $ - prompt
num_prompt:
	db "Num:", 13, 10
num_prompt_len: equ $ - num_prompt

write_byte: ; cl = byte to write, saves all
	push ax
	push bx
	mov al, cl
	and al, 0xF0
	shr al, 4
	cmp al, 9
	ja .letter1
	.digit1:
	add al, '0'
	jmp .write1
	.letter1:
	add al, 'A'-10
	.write1:
	mov ah, 0x0E
	mov bh, 0
	mov bl, 0
	int 0x10

	mov al, cl
	and al, 0x0F
	cmp al, 9
	ja .letter2
	.digit2:
	add al, '0'
	jmp .write2
	.letter2:
	add al, 'A'-10
	.write2:
	mov ah, 0x0E
	mov bh, 0
	mov bl, 0
	int 0x10
	pop bx
	pop ax
	ret
