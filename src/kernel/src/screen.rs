#![allow(static_mut_refs)]

use core::fmt::{Result, Write};
use core::ptr;

use crate::bios::video::*;

static mut GLOBAL_WRITER: ScreenWriter = ScreenWriter {
	mode: VideoMode::EGA,
	cur_x: 0,
	cur_y: 0,
	cur_style: 0x07,
};

pub struct GlobalScreen {}
impl GlobalScreen {
	pub unsafe fn init(mode: VideoMode) {
		GLOBAL_WRITER = ScreenWriter::new(mode);
	}
	pub fn scroll(lines: usize) {
		unsafe {
			GLOBAL_WRITER.scroll(lines);
		}
	}
	pub fn get_writer() -> &'static mut ScreenWriter {
		unsafe { &mut GLOBAL_WRITER }
	}
}

pub struct ScreenWriter {
	mode: VideoMode,
	cur_x: usize,
	cur_y: usize,
	cur_style: u8, // TODO: Make this a struct of some kind
}
impl ScreenWriter {
	fn new(mode: VideoMode) -> ScreenWriter {
		ScreenWriter {
			mode,
			cur_x: 0,
			cur_y: 0,
			cur_style: 0x07,
		}
	}

	fn scroll(&mut self, lines: usize) {
		let addr = self.mode.get_video_addr_start();
		let (width, height) = match self.mode {
			VideoMode::EGA => loop {}, // TODO:
			VideoMode::Color40x25 => (40, 25),
			VideoMode::Color80x25 => (80, 25),
			VideoMode::Mono80x25 => (80, 25),
		};

		let screen_size_bytes = width * height * 2;
		let bytes_ignored = lines * width * 2;

		unsafe {
			for dst_offset in 0..(screen_size_bytes - bytes_ignored) {
				let src_offset = dst_offset + bytes_ignored;
				ptr::write_volatile(&mut (*addr)[dst_offset], (*addr)[src_offset]);
			}
			for dst_offset in (screen_size_bytes - bytes_ignored)..screen_size_bytes {
				ptr::write_volatile(&mut (*addr)[dst_offset], 0x00);
			}
		}
	}
}
impl Write for ScreenWriter {
	fn write_str(&mut self, s: &str) -> Result {
		for c in s.chars() {
			self.write_char(c)?;
		}
		Ok(())
	}
	fn write_char(&mut self, c: char) -> Result {
		let (width, height) = match self.mode {
			VideoMode::EGA => loop {}, // TODO:
			VideoMode::Color40x25 => (40, 25),
			VideoMode::Color80x25 => (80, 25),
			VideoMode::Mono80x25 => (80, 25),
		};

		// Scroll the buffer and decrement y
		if self.cur_y >= height {
			self.scroll(height + 1 - self.cur_y);
			self.cur_y = height - 1;
		}

		// Process c
		match c {
			'\n' => {
				self.cur_x = 0;
				self.cur_y += 1;
			}
			_ => {
				let offset = ((self.cur_y * width) + self.cur_x) as usize;
				let addr = self.mode.get_video_addr_start();
				let c = if c.is_ascii_graphic() || c == ' ' {
					let mut bytes = [0; 4];
					c.encode_utf8(&mut bytes);
					bytes[0]
				} else {
					b'?'
				};

				unsafe {
					ptr::write_volatile(&mut (*addr)[offset * 2], c);
					ptr::write_volatile(&mut (*addr)[offset * 2 + 1], self.cur_style);
				}

				self.cur_x += 1;
			}
		}

		if self.cur_x >= width {
			self.cur_x = 0;
			self.cur_y += 1;
		}

		Ok(())
	}
}
