	%ifndef INC_KERNEL
	%define INC_KERNEL

	%include "stage2_include/gdt.asm"
	%include "stage2_include/bios_writes.asm"

	[bits 32]
_kstart:
	times 64 nop
	mov ebx, 0xDEADBEEF
	int 3

	jmp $ ; HALT

	%endif
