
%define coroutine_size 512

%include "coroutine.s"
%include "linux.s"

; An implementation of handle_conn that just echoes whatever the client sends
; it.  Mostly used for testing.

%define buf_size coroutine_scratch_size - 16

struc scratch
	.fd:     resq 1
	.filled: resq 1
	.buf:    resb buf_size
	.size:
endstruc

%if scratch.size > coroutine_scratch_size
	%error "Scratch size can't be greater than coroutine scratch size"
%endif

section .text

handle_conn:
	mov rax, SYS_READ
	mov rdi, r9
	lea rsi, [rbp+coroutin.scratch+scratch.buf]
	mov rdx, buf_size
	syscall
	mov qword [rbp+coroutin.scratch+scratch.filled], rax

	; We know have the request body in our buffer.
	; Let's parse the headers.

	coroutine_yield

	mov rax, SYS_WRITE
	mov rdi, [rbp+coroutin.scratch+scratch.fd]
	lea rsi, [rbp+coroutin.scratch+scratch.buf]
	mov rdx, [rbp+coroutin.scratch+scratch.filled]
	syscall

	mov rax, SYS_CLOSE
	mov rdi, [rbp+coroutin.scratch+scratch.fd]
	syscall

	coroutine_yield

section .data

%define crlf 13, 10

msg: db "HTTP/1.1 200 OK", crlf, "Content-Length: 6", crlf, crlf, "Hello!", crlf
msg_len: equ $ - msg

