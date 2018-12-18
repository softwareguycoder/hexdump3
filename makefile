hexdump3: hexdump3.o ../textlib/textlib.o
	ld -o hexdump3 hexdump3.o ../textlib/textlib.o -m elf_i386
hexdump3.o: hexdump3.asm
	nasm -f elf -g -F stabs hexdump3.asm -l hexdump3.lst
clean:
	rm -f *.o *.lst hexdump3
