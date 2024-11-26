#[derive(Clone, Copy)]
pub enum VideoMode {
	EGA,
	Color40x25,
	Color80x25,
	Mono80x25,
}
impl VideoMode {
	pub fn get_video_addr_start(self) -> *mut [u8; 0x8000] {
		match self {
			Self::EGA => 0xA0000 as *mut [u8; 0x8000],
			Self::Color40x25 | Self::Color80x25 => 0xB8000 as *mut [u8; 0x8000],
			Self::Mono80x25 => 0xB0000 as *mut [u8; 0x8000],
		}
	}
}
