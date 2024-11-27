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

	write!(GlobalScreen::get_writer(), "Allocating string\n").ok();
	let my_string = String::from_str("HI I'M ON THE HEAP YIPPEE").unwrap();
	write!(GlobalScreen::get_writer(), "Printing string\n").ok();
	write!(GlobalScreen::get_writer(), "{}\n", my_string).ok();
	write!(GlobalScreen::get_writer(), "Deallocating string\n").ok();
	drop(my_string);

	write!(GlobalScreen::get_writer(), "Creating vec\n").ok();
	let mut my_vec: Vec<u64> = Vec::new();
	write!(GlobalScreen::get_writer(), "Pushing nums 0-199\n").ok();
	for i in 0..200 {
		my_vec.push(i);
	}
	write!(
		GlobalScreen::get_writer(),
		"Consuming and checking vec contents\n"
	)
	.ok();
	for (v, t) in my_vec.into_iter().zip(0..) {
		if v != t {
			write!(GlobalScreen::get_writer(), "Incorrect value at {}\n", t).ok();
		}
	}
	write!(GlobalScreen::get_writer(), "Done!\n").ok();

	loop {}
}
