pub mod allocator;

use core::fmt::Display;
use core::ptr;

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
		// The pointer does not need to be aligned, so the previous implementation was UB
		ptr::read_unaligned(entry)
	}
}

pub enum Type {
	Usable,
	Reserved,
	ACPIReclaimable,
	ACPINonVolatile,
	Bad,
}
impl TryFrom<u32> for Type {
	type Error = ();
	fn try_from(v: u32) -> Result<Self, Self::Error> {
		match v {
			1 => Ok(Self::Usable),
			2 => Ok(Self::Reserved),
			3 => Ok(Self::ACPIReclaimable),
			4 => Ok(Self::ACPINonVolatile),
			5 => Ok(Self::Bad),
			_ => Err(()),
		}
	}
}
impl Display for Type {
	fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
		match self {
			Self::Usable => 1,
			Self::Reserved => 2,
			Self::ACPIReclaimable => 3,
			Self::ACPINonVolatile => 4,
			Self::Bad => 5,
		}
		.fmt(f)
	}
}

pub struct ExtendedAttributes {
	pub ignore: bool,
	pub non_volatile: bool,
}
impl From<u32> for ExtendedAttributes {
	fn from(v: u32) -> Self {
		ExtendedAttributes {
			ignore: !((v & 0b01) > 0),
			non_volatile: (v & 0b10) > 0,
		}
	}
}
impl Display for ExtendedAttributes {
	fn fmt(&self, f: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
		(u32::from(!self.ignore) | u32::from(self.non_volatile) << 1).fmt(f)
	}
}

pub struct MemoryEntry {
	pub base: u64,
	pub length: u64,
	pub region_type: Type,
	pub extended_attr: ExtendedAttributes,
}
impl MemoryEntry {
	fn from_raw_entry(entry: MemoryEntryRaw) -> MemoryEntry {
		MemoryEntry {
			base: entry.base,
			length: entry.length,
			region_type: entry.region_type.try_into().unwrap_or(Type::Bad),
			extended_attr: entry.extended_attr.into(),
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
