
main: main.o
	ld -o main main.o

main.o: main.s
	nasm -f elf64 -o main.o main.s

clean:
	rm -f main.o main

