#![no_std]
#![no_main]

use core::arch::asm;
use core::panic;

const MEMORY_MAP_NUM_ENTRIES: *const u32 = 0x7000 as *const u32;
const MEMORY_MAP_START: *const MemoryEntry = 0x7004 as *const MemoryEntry;

#[repr(C, packed)]
#[derive(Clone, Copy)]
struct MemoryEntry {
	base: u64,
	length: u64,
	region_type: u32,
	extended_attr: u32,
}
impl MemoryEntry {
	fn from_raw_ptr(entry: *const MemoryEntry) -> MemoryEntry {
		unsafe { *entry }
	}
}

fn get_mmap_num_entries() -> u32 {
	unsafe { *MEMORY_MAP_NUM_ENTRIES }
}

fn get_mmap_entry(index: u32) -> Option<MemoryEntry> {
	let num_entries = get_mmap_num_entries();
	if index >= num_entries {
		return None;
	}

	unsafe {
		Some(MemoryEntry::from_raw_ptr(
			MEMORY_MAP_START.offset(index as isize),
		))
	}
}

#[panic_handler]
fn panic_handle(_info: &panic::PanicInfo) -> ! {
	loop {}
}

#[no_mangle]
extern "cdecl" fn _kstart() -> ! {
	let num_entries = get_mmap_num_entries();
	for i in 0..num_entries {
		let cur_entry = get_mmap_entry(i);
		match cur_entry {
			None => (),
			Some(v) => unsafe {
				// Put it in an easy to find location so I can check the results in GDB
				asm!(
				 "mov eax, {}",
				 "mov ecx, {}",
				 in(reg) (v.base & 0xFFFFFFFF) as u32,
				 in(reg) ((v.base & 0xFFFFFFFF00000000) >> 32) as u32,
				 out("eax") _,
				 out("ecx") _,
				);
				asm!(
				 "mov eax, {}",
				 "mov ecx, {}",
				 in(reg) (v.length & 0xFFFFFFFF) as u32,
				 in(reg) ((v.length & 0xFFFFFFFF00000000) >> 32) as u32,
				 out("eax") _,
				 out("ecx") _,
				);
				asm!(
				 "mov eax, {}",
				 in(reg) v.region_type,
				 out("eax") _,
				);
			},
		}
	}
	loop {}
}
