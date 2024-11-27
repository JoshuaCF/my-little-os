#![no_std]

extern crate alloc;

mod bios;
mod memory;
mod screen;

use core::fmt::Write;
use core::panic;

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
	let mut screen = GlobalScreen::writer();
	screen.scroll(3);
	write!(screen, "Initializing allocator\n").ok();

	unsafe {
		KernelAllocator::init();
	}

	loop {}
}
