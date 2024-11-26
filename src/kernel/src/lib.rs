#![no_std]

mod bios;
mod memory;
mod screen;

use core::fmt::Write;
use core::panic;

use bios::*;
use memory::*;
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
	let mut screen = ScreenWriter::new(video_mode);
	screen.scroll(3);

	let num_entries = get_mmap_num_entries();
	for i in 0..num_entries {
		let cur_entry = get_mmap_entry(i);
		match cur_entry {
			None => (),
			Some(v) => {
				write!(
					screen,
					"Base: 0x{:<12X} Length: 0x{:<10X} Type: {:<2} Attr: {:<2}\n",
					v.base, v.length, v.region_type, v.extended_attr
				)
				.ok();
			}
		}
	}
	loop {}
}
