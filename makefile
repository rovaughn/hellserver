
test: echo
	./test.sh

echo: echo.o
	ld -o $@ $^

echo.o: main.s constants.s coroutine.s echo.s
	nasm -f elf64 -g -o $@ -d listen_port=8000 -p echo.s main.s

clean:
	xargs -a .gitignore rm -f

