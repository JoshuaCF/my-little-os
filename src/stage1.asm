; sits in the MBR, sole purpose is to load stage2
	[bits 16]
	section raw
	align 1

stage2_first_sector: equ 1
stage2_sectors: equ 8
stage2_location: equ 0x1000

; set up a stack
	lss sp, [lss_data]

; zero segments
	xor ax, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

; set up read packet
	mov byte [packet + 0], 0x10 ; packet size
	mov word [packet + 2], stage2_sectors ; num sectors to read
	mov word [packet + 4], stage2_location ; byte offset to read to
	mov word [packet + 6], 0x0000 ; segment to read to
	mov word [packet + 8], stage2_first_sector ; start sector of data

; read stage2 from the hdd starting at sector 1 to stage2_location
; could modify this later to instead read an active partition?
; perform read
	mov ah, 0x42
	; dl already contains the drive number from BIOS
	mov bx, 0
	mov ds, bx
	mov si, packet
	int 0x13

; enforce CS:IP and jump to stage 2
	jmp 0x0000:stage2_location

packet:
	times 16 db 0

; initializes stack at 0x1000
; current setup allows 4KiB of stack space (WRONG!)
; there's an interrupt table starting at 0x0400, which shouldn't be damaged
; the BIOS reserves extra data up to 0x04FF, so 0x0500 is the first usable address
; this stack allows only 2KiB (until we get to 32-bit mode, in which case we should be allowed to clobber this space)
lss_data:
	dw 0x1000, 0x0000
