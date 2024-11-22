	%ifndef INC_BIOS_WRITES
	%define INC_BIOS_WRITES

	[bits 16]
write_crlf: ; clobbers ax, bx
	mov al, `\r`
	call write_char
	call write_lf
	ret

write_lf: ; clobbers ax, bx
	mov al, `\n`
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

	%endif
