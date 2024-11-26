#!/bin/bash

if [[ ! -e ./bin ]]; then
	mkdir ./bin
fi
if [[ ! -e ./target ]]; then
	mkdir ./target
fi

echo "Removing old image..."
if [[ -e ./target/boot.img ]]; then
	rm ./target/boot.img
fi
echo "Creating blank disk image of size 2G..."
dd if=/dev/null of=./target/boot.img bs=1G count=0 seek=2 status=progress

echo "Running build scripts..."
for filename in ./src/*.asm; do
	base="$(basename $filename .asm)"
	nasm -g -I "src/" -f "elf" -wall -o "./bin/${base}" $filename
done
cd src/kernel
cargo build
cargo build --release
cd ../..
cp src/kernel/target/i686-none-eabi/debug/libkernel.a bin/kerneldbg.a
cp src/kernel/target/i686-none-eabi/release/libkernel.a bin/kernel.a

echo "Running linker scripts..."
ld -T linkerscript.ld --gc-sections
# I use the following file to get symbols for GDB
# Feels dodgy, but it's worked well enough so far
ld -T linkerscript_debug.ld --gc-sections

echo "Patching disk image..."
dd_common="of=./target/boot.img conv=notrunc status=progress"
dd $dd_common if=./bin/out
# dd $dd_common if=./bin/partitions bs=1 seek=446
# dd $dd_common if=./bin/stage1 bs=1
# dd $dd_common if=./bin/stage2 bs=512 seek=1
