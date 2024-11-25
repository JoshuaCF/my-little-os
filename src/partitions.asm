struc part_entry
	.attributes resb 1
	.chs_start resb 3
	.part_type resb 1
	.chs_end resb 3
	.lba_start resb 4
	.num_sectors resb 4
endstruc

; assuming qemu default disk geometry of 1040/16/63
; sector starts at 1
%define cylinder(lba) (lba / (16 * 63))
%define head(lba) ((lba / 63) % 16)
%define sector(lba) ((lba % 63) + 1)

%define chs_from_lba(lba) head(lba), ((cylinder(lba) & 0x300) >> 2) | sector(lba), cylinder(lba) & 0xFF

; attributes (0x80 for bootable/active, 0x00 otherwise)
; partition type (i'm just gonna use 0xCF tbh)
; lba start
; number of sectors
%macro def_part 4
istruc part_entry
	at .attributes
	db %1
	at .chs_start
	db chs_from_lba(%3)
	at .part_type
	db %2
	at .chs_end
	db chs_from_lba(%3 + %4)
	at .lba_start
	dd %3
	at .num_sectors
	dd %4
iend
%endmacro

%macro def_part 0
	times part_entry_size db 0
%endmacro

	[bits 16]
	section raw
	align 1
	def_part 0x80, 0xCF, 1, 16
	def_part
	def_part
	def_part
	db 0x55, 0xAA ; boot signature
