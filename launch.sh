qemu-system-x86_64 \
	-drive file=./build/boot.img,media=disk,index=0,format=raw \
	-boot order=c \
	-m 1M
