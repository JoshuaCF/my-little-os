const MEMORY_MAP_NUM_ENTRIES: *const u32 = 0x7000 as *const u32;
const MEMORY_MAP_START: *const MemoryEntryRaw = 0x7004 as *const MemoryEntryRaw;

#[repr(C, packed)]
#[derive(Clone, Copy)]
struct MemoryEntryRaw {
	base: u64,
	length: u64,
	region_type: u32,
	extended_attr: u32,
}
impl MemoryEntryRaw {
	unsafe fn from_raw_ptr(entry: *const MemoryEntryRaw) -> MemoryEntryRaw {
		*entry
	}
}

pub struct MemoryEntry {
	pub base: u64,
	pub length: u64,
	pub region_type: u32,
	pub extended_attr: u32,
}
impl MemoryEntry {
	fn from_raw_entry(entry: MemoryEntryRaw) -> MemoryEntry {
		MemoryEntry {
			base: entry.base,
			length: entry.length,
			region_type: entry.region_type,
			extended_attr: entry.extended_attr,
		}
	}
}

pub fn get_mmap_num_entries() -> u32 {
	unsafe { *MEMORY_MAP_NUM_ENTRIES }
}

pub fn get_mmap_entry(index: u32) -> Option<MemoryEntry> {
	let num_entries = get_mmap_num_entries();
	if index >= num_entries {
		return None;
	}

	unsafe {
		Some(MemoryEntry::from_raw_entry(MemoryEntryRaw::from_raw_ptr(
			MEMORY_MAP_START.offset(index as isize),
		)))
	}
}
