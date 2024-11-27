#![no_std]

extern crate alloc;

mod bios;
mod memory;
mod screen;

use core::fmt::Write;
use core::panic;
use core::str::FromStr;

use alloc::string::String;
use alloc::vec::Vec;

use bios::*;
use memory::allocator::*;
use screen::*;

#[panic_handler]
fn panic_handle(_info: &panic::PanicInfo) -> ! {
	loop {}
}

#[no_mangle]
pub extern "cdecl" fn _kstart() -> ! {
	// get video mode
	let video_mode = match BiosDataRaw::get_video_mode() {
		Ok(mode) => mode,
		Err(_) => loop {},
	};
	unsafe {
		GlobalScreen::init(video_mode);
	}
	GlobalScreen::scroll(3);
	write!(GlobalScreen::get_writer(), "Initializing allocator\n").ok();

	unsafe {
		KernelAllocator::init();
	}

	KernelAllocator::print_ranges();

	write!(GlobalScreen::get_writer(), "Creating vec\n").ok();
	let mut my_vec: Vec<u64> = Vec::new();
	write!(GlobalScreen::get_writer(), "Pushing nums\n").ok();
	for i in 0..10 {
		my_vec.push(i);
	}
	KernelAllocator::print_ranges();

	write!(GlobalScreen::get_writer(), "Deallocating vector\n").ok();
	drop(my_vec);
	KernelAllocator::print_ranges();

	write!(GlobalScreen::get_writer(), "Done!\n").ok();

	loop {}
}
