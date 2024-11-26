pub mod video;

use core::ptr;

use video::*;

const BIOS_DATA_AREA: *const BiosDataRaw = 0x400 as *const BiosDataRaw;

#[repr(C, packed)]
pub struct BiosDataRaw {
	bytes: [u8; 256],
}
impl BiosDataRaw {
	pub fn get_video_mode() -> Result<VideoMode, ()> {
		let video_mode_byte;
		unsafe {
			video_mode_byte = (ptr::read(BIOS_DATA_AREA).bytes[0x10] & 0b00110000) >> 4;
		}

		match video_mode_byte {
			0 => Ok(VideoMode::EGA),
			1 => Ok(VideoMode::Color40x25),
			2 => Ok(VideoMode::Color80x25),
			3 => Ok(VideoMode::Mono80x25),
			_ => Err(()),
		}
	}
}
