/* Basic configuration */
INPUT(bin/stage1 bin/stage2 bin/partitions bin/kernel.a)
OUTPUT_ARCH(i386)
OUTPUT_FORMAT(elf64-x86-64)
OUTPUT(bin/dbg)

SECTIONS {
	/*
	Stage 1 goes before partitions
	The MBR is loaded into address 0x7C00
	*/

	mbr_code 0x500 : {
		bin/stage1(raw)
	}
	
	/* Partitions start at byte 446 */
	mbr_data : {
		bin/partitions(raw)
	}
	/*
	Stage 2 is loaded by the stage 1 to address 0x1000
	The data is physically stored starting at the first non-MBR sector
	The kernel should go immediately after stage 2
	*/
	partition0 0x9000 : {
		bin/stage2(raw)
		bin/kernel.a(*)
	}

	/DISCARD/ : {
		*(*)
	}
}
