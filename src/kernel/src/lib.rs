#![no_std]
#![no_main]

use core::arch::asm;
use core::panic;

#[panic_handler]
fn panic_handle(_info: &panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
extern "cdecl" fn _kstart() -> ! {
    loop {}
}
