#!/bin/bash

# qemu default disk geometry is 1040/16/63
qemu-system-x86_64 \
	-drive file=./build/boot.img,media=disk,index=0,format=raw \
	-boot order=c \
	-m 64M
