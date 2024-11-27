use core::alloc::GlobalAlloc;
use core::alloc::Layout;
use core::fmt::Write;
use core::ptr;
use core::sync::atomic::{AtomicBool, Ordering};

use crate::memory::*;
use crate::screen::GlobalScreen;

// Needs to be initialized with information on the current state of memory
// I can also pass ownership of existing data structures from stage 2 so that
// the allocator can free the memory when I'm done with it
#[global_allocator]
pub static KERNEL_ALLOCATOR: KernelAllocator = KernelAllocator {};
// this feels gross asf
static LOCK: AtomicBool = AtomicBool::new(false);
static mut RANGE_COUNT: usize = 0; // Number of ranges
static mut RANGE_CAPACITY: usize = 0; // Allowed max ranges
static mut USABLE_RAM: *mut Range = ptr::null_mut(); // List of usable ram ranges

const GLOBAL_ALIGN: usize = 512;
fn round_to_align(val: usize) -> usize {
	val + (GLOBAL_ALIGN - (val % GLOBAL_ALIGN)) % GLOBAL_ALIGN // double mod feels silly
}

pub struct KernelAllocator {}
impl KernelAllocator {
	pub unsafe fn init() {
		let num_entries = get_mmap_num_entries();
		for i in 0..num_entries {
			let cur_entry = get_mmap_entry(i);
			match cur_entry {
				None => (),
				Some(v) => {
					if let Type::Usable = v.region_type {
						// Convert the region into a range
						let mut new_range = Range {
							base: v.base,
							length: v.length,
						};

						// Ignore addresses 0x00000000-0x0007FFFF for now -- the kernel and
						// other critical data occupies unknown locations in this range
						if new_range.base <= 0x0007FFFF {
							// If the entry lies entirely in the ignored region, skip it
							if new_range.end() <= 0x0007FFFF {
								continue;
							}
							// Otherwise, cut off the ignored portion
							let new_length = new_range.end() - 0x0007FFFF;
							new_range.base += new_range.length - new_length;
							new_range.length = new_length;
						}

						// Align base
						let new_base = round_to_align(new_range.base as usize);
						let lost_bytes = new_base - new_range.base as usize;
						new_range.base = new_base as u64;
						new_range.length -= lost_bytes as u64;

						// If this is the first usable region, set up ranges
						if RANGE_CAPACITY == 0 {
							// Target start capacity is 64
							// If we can't support that, just skip the tiny range
							// Suboptimal, but easy
							let required_bytes = round_to_align(2 * core::mem::size_of::<Range>());
							if v.length < required_bytes as u64 {
								continue;
							}

							// Remove the allocated space from the range
							USABLE_RAM = new_range.base as *mut Range;
							new_range.base += required_bytes as u64;
							new_range.length -= required_bytes as u64;

							RANGE_CAPACITY = 2;
						}

						if RANGE_CAPACITY != 0 {
							*USABLE_RAM.offset(RANGE_COUNT as isize) = new_range;
							RANGE_COUNT += 1;
						}
					}
				}
			}
		}
	}

	pub fn print_ranges() {
		unsafe {
			for i in 0..RANGE_COUNT {
				write!(
					GlobalScreen::writer(),
					"{:?}\n",
					*USABLE_RAM.offset(i as isize)
				)
				.ok();
			}
		}
	}

	// Function is only ever called inside a dealloc, after a lock has been obtained
	// This means it should be safe to do unchecked allocations
	unsafe fn realloc_ranges(&self) {
		// TODO: Perform a range merge before reallocating
		let old_cap = RANGE_CAPACITY;
		let old_ram = USABLE_RAM;
		RANGE_CAPACITY *= 2;
		let layout = Layout::array::<Range>(RANGE_CAPACITY).unwrap();
		let dest: *mut Range = self.alloc_unchecked(layout) as *mut Range;

		for index in 0..RANGE_COUNT {
			*(dest.offset(index as isize)) = ptr::read(USABLE_RAM.offset(index as isize));
		}

		USABLE_RAM = dest;
		self.dealloc_unchecked(old_ram as *mut u8, Layout::array::<Range>(old_cap).unwrap());
	}
	unsafe fn remove_range(index: usize) {
		RANGE_COUNT -= 1;
		if index == RANGE_COUNT {
			return;
		}

		*USABLE_RAM.offset(index as isize) = ptr::read(USABLE_RAM.offset(RANGE_COUNT as isize));
	}

	fn get_lock() {
		// I have no idea if this works, I've never used atomics
		loop {
			match LOCK.compare_exchange(false, true, Ordering::AcqRel, Ordering::Acquire) {
				Ok(_) => break,
				Err(_) => (),
			};
			core::hint::spin_loop();
		}
	}
	fn release_lock() {
		LOCK.store(false, Ordering::Release);
	}

	// Not thread safe! Ensure that a lock is obtained before using these
	unsafe fn alloc_unchecked(&self, layout: Layout) -> *mut u8 {
		let mut ret_ptr = ptr::null_mut();
		let size = round_to_align(layout.size());

		if RANGE_CAPACITY != 0 {
			// Find a free spot to allocate the requested data
			// Algorithm: scan backwards through usable ram ranges until finding one large enough
			// to support the data (round size up to nearest multiple of GLOBAL_ALIGN)
			// Once found, remove from the front of the range and return the pointer which
			// corresponds to the base of the range
			for i in (0..RANGE_COUNT).rev() {
				let cur_range = &mut *USABLE_RAM.offset(i as isize);
				if cur_range.length as usize > size {
					ret_ptr = cur_range.base as *mut u8;
					cur_range.base += size as u64;
					cur_range.length -= size as u64;
					if cur_range.length == 0 {
						KernelAllocator::remove_range(i);
					}
					break;
				}
			}
		}

		ret_ptr
	}
	unsafe fn dealloc_unchecked(&self, ptr: *mut u8, layout: Layout) {
		let base = ptr as u64;
		let size = round_to_align(layout.size());
		let freed_range = Range {
			base,
			length: size as u64,
		};

		let mut merge_success = false;
		for i in 0..RANGE_COUNT {
			match (&mut *USABLE_RAM.offset(i as isize)).try_merge(&freed_range) {
				Ok(_) => {
					merge_success = true;
					break;
				}
				_ => (),
			}
		}

		if !merge_success {
			// Append the range
			*USABLE_RAM.offset(RANGE_COUNT as isize) = freed_range;
			RANGE_COUNT += 1;
		}
	}
}
unsafe impl GlobalAlloc for KernelAllocator {
	unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
		KernelAllocator::get_lock();
		let ptr = self.alloc_unchecked(layout);
		KernelAllocator::release_lock();
		ptr
	}
	unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
		KernelAllocator::get_lock();
		// Allocate more room for ranges if at capacity
		if RANGE_CAPACITY == RANGE_COUNT {
			self.realloc_ranges();
		}
		self.dealloc_unchecked(ptr, layout);
		KernelAllocator::release_lock();
	}
}

#[derive(Debug)]
struct Range {
	base: u64,
	length: u64,
}
impl Range {
	fn end(&self) -> u64 {
		self.base + self.length
	}

	fn try_merge(&mut self, other: &Range) -> Result<(), ()> {
		if other.end() == self.base {
			self.base = other.base;
			self.length += other.length;
			Ok(())
		} else if self.end() == other.base {
			self.length += other.length;
			Ok(())
		} else {
			Err(())
		}
	}
}
