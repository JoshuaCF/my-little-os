#![no_std]
#![no_main]

use core::arch::asm;
use core::panic;

#[panic_handler]
fn phandle(_info: &panic::PanicInfo) -> ! {
    loop {}
}

#[no_mangle]
extern "cdecl" fn _kstart() -> ! {
    let ten_factorial = factorial(10);
    // put the result in eax so i know where to check
    unsafe {
        asm!(
            "",
            in("eax") ten_factorial,
        );
    }
    loop {}
}

#[no_mangle]
#[inline(never)]
fn factorial(num: usize) -> usize {
    (1..=num).fold(1, |acc, e| acc * e)
}
