; will be loaded into ram by stage1.asm
	[bits 16]
	org 0x1000

	jmp _init

	%include "stage2_include/idt.asm"
	%include "stage2_include/task.asm"
	%include "stage2_include/gdt.asm"
	%include "stage2_include/bios_writes.asm"

	[bits 16]

; set up cursor
_init:
	mov ah, 0x01
	mov ch, 0x00
	mov cl, 0x0F
	int 0x10

; announce stage 2
	mov bp, str_stage2
	mov cx, str_stage2_len
	call write_str

; test A20 line
	mov bp, str_test_a20
	mov cx, str_test_a20_len
	call write_str

	mov ax, 0xFFFF
	mov gs, ax

	mov ax, [ds:0x7DFE]
	mov bx, [gs:0x7E0E]
	cmp ax, bx
	jne .enable_end

	mov word [ds:0x7DFE], 0x0000
	mov ax, [ds:0x7DFE]
	cmp ax, bx
	jne .enable_end

; enable A20 line
	mov bp, str_set_a20
	mov cx, str_set_a20_len
	call write_str

; i don't know how this works and i should look into it
	in al, 0x92
	or al, 2
	out 0x92, al
	in al,0xee

	.enable_end:

; build and clone idt
	call fill_idt
	mov esi, idt_init
	mov edi, idtr_addr
	mov ecx, 8*22
	rep movsb

; clone gdt
	mov esi, gdt_init
	mov edi, gdtr_addr
	mov ecx, 8*6
	rep movsb

; disable all interrupts while switching into protected mode
	cli
	in al, 0x70
	and al, 0x7F
	out 0x70, al

; disable PIC
	mov al, 0xFF
	out 0x21, al
	out 0xA1, al
; it may still generate spurious interrupts, so remap it
	mov al, 0x11
	out 0x20, al
	out 0xA0, al
	mov al, 0x20
	out 0x21, al
	mov al, 0x28
	out 0xA1, al
	mov al, 4
	out 0x21, al
	mov al, 2
	out 0xA1, al
	mov al, 1
	out 0x21, al
	out 0xA1, al

; set up TSS
	call fill_tss

; set up GDT
	lgdt [gdtr]

; enable protected mode
	mov bp, str_enable_pe
	mov cx, str_enable_pe_len
	call write_str

	mov eax, cr0
	or eax, 1
	mov cr0, eax

	jmp seg_selector(1, 0, 0):dword .next_instr

	[bits 32]
	.next_instr:

; set up task
	mov ax, seg_selector(3, 0, 0)
	ltr ax

; set up segment registers to use 32 bit data segment
	mov ax, seg_selector(2, 0, 0)
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax

; set up IDT
	lidt [idtr]

	sti

	jmp seg_selector(1, 0, 0):dword _kstart

	[bits 16]

str_stage2:
	db "Running stage 2", `\r\n`
str_stage2_len: equ $ - str_stage2
str_test_a20:
	db "Testing A20", `\r\n`
str_test_a20_len: equ $ - str_test_a20
str_set_a20:
	db "Setting A20", `\r\n`
str_set_a20_len: equ $ - str_set_a20
str_enable_pe:
	db "Enabling PE", `\r\n`
str_enable_pe_len: equ $ - str_enable_pe

	%include "stage2_include/kernel.asm"