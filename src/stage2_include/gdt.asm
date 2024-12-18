	%ifndef INC_GDT
	%define INC_GDT

	%include "stage2_include/constants.asm"
	[bits 16]

	%define seg_selector(index, table, rpl) index << 3 | table << 2 | rpl

; base, limit, flags_low, flags_high, type
; flags_low = present, DPL(2), type
; flags_high = granularity, def_size, 64-bit, custom
	%macro gdt_entry 5
	dd ((%1 & 0x0000FFFF) << 16) | (%2 & 0x0000FFFF)
	dd (%1 & 0xFF000000) | ((%4 & 0xF) << 20) | (%2 & 0x000F0000) | ((%3 & 0xF) << 12) | ((%5 & 0xF) << 8) | ((%1 & 0x00FF0000) >> 16)
	%endmacro

gdtr: 
	dw 4 * 8 ; 8192 total entries allowed, limit to 4 for now
	dd gdtr_addr

gdt_init:
	dd 0
	dd 0
; ram-wide kernel code segment
	gdt_entry 0x0, 0xFFFFF, 0b1001, 0b1100, 10
; ram-wide kernel data segment
	gdt_entry 0x0, 0xFFFFF, 0b1001, 0b1100, 2
; kernel task segment
	gdt_entry tss_addr, 0x67, 0b1000, 0b0000, 9

	%endif
