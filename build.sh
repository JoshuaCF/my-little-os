#!/bin/bash

if [[ ! -e ./bin ]]; then
	mkdir ./bin
fi
if [[ ! -e ./build ]]; then
	mkdir ./build
fi

echo "Removing old image..."
if [[ -e ./build/boot.img ]]; then
	rm ./build/boot.img
fi
echo "Creating blank disk image of size 1MiB..."
dd if=/dev/null of=./build/boot.img count=0 seek=2048 status=progress

echo "Assembling source..."
for filename in ./src/*.asm; do
	base="$(basename $filename .asm)"
	nasm -I "src/" -g -wall -o "./bin/${base}" $filename
done

echo "Patching disk image..."
dd_common="of=./build/boot.img conv=notrunc status=progress"
dd $dd_common if=./bin/partitions bs=1 seek=446
dd $dd_common if=./bin/stage1 bs=1
dd $dd_common if=./bin/stage2 bs=512 seek=1
