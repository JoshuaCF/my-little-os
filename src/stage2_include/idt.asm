	%ifndef INC_IDT
	%define INC_IDT

	%include "stage2_include/gdt.asm"
	%include "stage2_include/bios_writes.asm"

	[bits 16]
; selector, offset, flags, size
; flags = present, DPL(2)
	%macro idt_entry_intgate 4
	dd ((%1 & 0x0000FFFF) << 16) | (%2 & 0x0000FFFF)
	dd (%2 & 0xFFFF0000) | ((%3 & 0x7) << 13) | ((%4 & 0x1) << 11) | 0x600
	%endmacro

no_err_tbl:
	dw 0,1,2,3,4,5,6,7,9,15,16,18,19,20,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47
no_err_tbl_len: equ $ - no_err_tbl
err_tbl:
	dw 8,10,11,12,13,14,17,21
err_tbl_len: equ $ - err_tbl

fill_idt:
	xor si, si

	.no_err_tbl_loop:
	mov di, [si + no_err_tbl]
	shl di, 3
	mov word [di + idt_init], handler_noerr
	add si, 2
	cmp si, no_err_tbl_len
	jb .no_err_tbl_loop

	xor si, si
	.err_tbl_loop:
	mov di, [si + err_tbl]
	shl di, 3
	mov word [di + idt_init], handler_err
	add si, 2
	cmp si, err_tbl_len
	jb .err_tbl_loop

	ret

idtr_addr: equ 0x00006000
idtr: 
	dw 0xFF ; 256 total entries allowed
	dd idtr_addr

idt_init:
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 
	idt_entry_intgate seg_selector(1, 0, 0), 0x0, 0b100, 1 

	[bits 32]
; SUPER TEMPORARY JUST TO GET THINGS WORKING, PROPER INTERRUPTS SHOULD BE SET UP BY THE KERNEL
handler_noerr:
	iretd
handler_err:
	pop eax
	iretd

	%endif
