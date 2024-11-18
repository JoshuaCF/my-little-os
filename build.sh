#!/bin/bash

if [[ ! -e ./bin ]]; then
	mkdir ./bin
fi
if [[ ! -e ./build ]]; then
	mkdir ./build
fi

echo "Looking for disk image..."
if [[ ! -e ./build/boot.img ]]; then
	echo "Creating zeroed disk image of size 1MiB..."
	dd if=/dev/null of=./build/boot.img count=0 seek=2048 status=progress
fi

echo "Assembling source..."
for filename in ./src/*.asm; do
	base="$(basename $filename .asm)"
	nasm -g -wall -o "./bin/${base}" $filename
done

echo "Patching disk image..."
dd if=/dev/zero of=./build/boot.img bs=1 count=512 conv=notrunc status=progress
dd if=./bin/bootloader of=./build/boot.img conv=notrunc bs=1 status=progress
dd if=./bin/partitions of=./build/boot.img conv=notrunc bs=1 seek=446 status=progress
