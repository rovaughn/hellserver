
.PHONY: unit-test echo-test

unit-test.o: test.s http.s
	nasm -f elf64 -g -o unit-test.o test.s

unit-test.out: unit-test.o
	ld -o $@ $^

unit-test: unit-test.out
	valgrind -q ./unit-test.out

echo-test: echo echo-test.sh
	./echo-test.sh

echo: echo.o
	ld -o $@ $^

echo.o: main.s linux.s coroutine.s echo.s
	nasm -f elf64 -g -o $@ -d listen_port=8000 -p echo.s main.s

clean:
	xargs -a .gitignore rm -f

