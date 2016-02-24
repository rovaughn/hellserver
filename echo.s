
%define coroutine_size 512

%include "coroutine.s"
%include "constants.s"

; An implementation of handle_conn that just echoes whatever the client sends
; it.  Mostly used for testing.

struc scratch
	.fd: resq 1
	.buf: resb 256
endstruc

section .text

handle_conn:
	mov rax, SYS_READ
	mov rdi, r9
	mov rsi, [rbp+coroutin.scratch+scratch.buf]
	mov rdx, 256
	syscall

	coroutine_yield

	mov rax, SYS_WRITE
	mov rdi, [rbp+coroutin.scratch+scratch.fd]
	mov rsi, msg
	mov rdx, msg_len
	syscall

	mov rax, SYS_CLOSE
	mov rdi, [rbp+coroutin.scratch+scratch.fd]
	syscall

	coroutine_yield

section .data

%define crlf 13, 10

msg: db "HTTP/1.1 200 OK", crlf, "Content-Length: 6", crlf, crlf, "Hello!", crlf
msg_len: equ $ - msg

