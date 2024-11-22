	%ifndef INC_TASK
	%define INC_TASK

	%include "stage2_include/gdt.asm"
	[bits 16]

fill_tss:
	; 0 the whole structure first for sanity
	mov si, 0
	.zero_loop:
	mov byte [0x3000 + si], 0
	inc si
	cmp si, 104
	jb .zero_loop

	mov dword [0x3000 + 4], 0x1000 ; esp0 = 0x1000
	mov word [0x3000 + 8], seg_selector(2, 0, 0) ; ss0 = data segment
	; IOBP should be directly at the top of the TSS
	; due to limit in GDT, no IO ports should be specified
	mov word [0x3000 + 102], 104 ; IOBP
	ret

	%endif
