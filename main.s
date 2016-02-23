
; struct sockaddr_in {
; 	uint16_t      sin_family;
;   uint16_t      sin_port;
;   uint32_t      sin_addr;
;   unsigned char __pad[8];
; }

struc sockaddr_in
	.family: resw 1
	.port:   resw 1
	.addr:   resd 1
	.pad:    resb 8
	.size:
endstruc

; struct sockaddr {
; 	uint16_t sa_family;
;	char     sa_data[14];
; }

struc sockaddr
	.family: resw 1
	.data:   resb 14
	.size:
endstruc

; typedef union epoll_data {
;	void     *ptr;
;	int       fd;
;   uint32_t  u32;
;   uint64_t  u64;
; }
;
; struct epoll_event {
; 	uint32_t     events;
;	epoll_data_t data;
; }

struc epoll_event
	.events: resd 1
	.data:   resq 1
	.size:
endstruc

struc coroutine
	.rip:     resq 1
	.ret:     resq 1
	.scratch: resb (256 - 16)
	.size:
endstruc

%define SYS_SOCKET        41
%define SYS_SETSOCKOPT    54
%define SYS_BIND          49
%define SYS_LISTEN        50
%define SYS_EPOLL_CREATE 213
%define SYS_EPOLL_CTL    233
%define SYS_ACCEPT        43
%define SYS_READ           0
%define SYS_WRITE          1
%define SYS_CLOSE          3
%define SYS_EPOLL_WAIT   232

%define SO_REUSEADDR  2
%define PF_INET       2
%define SOCK_STREAM   1
%define IPPROTO_IP    0
%define SOL_SOCKET    1
%define EPOLL_CTL_ADD 1
%define EPOLLIN       1
%define EPOLLET       (1<<31)
%define STDIN_FILENO  0
%define STDOUT_FILENO 1
%define STDERR_FILENO 2

%define MAX_EVENTS     10
%define MAX_COROUTINES 10
%define BACKLOG        5

%define listening_fd 3
%define epoll_fd     4

; Jumps into a coroutine whose address is %1.  Sets up its stack so that it will
; return to where it was called.  Coroutine can't use rbp.
%macro coroutine_call 0
	; Set the return address.
	mov qword [rbp + coroutine.ret], %%after

	; Jump
	jmp [rbp + coroutine.rip]
%%after:
%endmacro

%macro coroutine_yield 0
	mov qword [rbp + coroutine.rip], %%after
	jmp [rbp + coroutine.ret]
%%after:
%endmacro

section .text

global _start

listening_coroutine:
	mov rax, SYS_ACCEPT
	mov rdi, listening_fd
	mov rsi, accept_sockaddr
	mov rdx, accept_addrlen
	syscall
	mov r9, rax

	mov rbx, r9
	sal rbx, 8
	mov qword [coroutines+rbx+coroutine.rip], handle_socket
	mov qword [coroutines+rbx+coroutine.scratch+handle_socket_scratch.fd], r9

	mov dword [temp_epoll_event+epoll_event.events], EPOLLIN
	mov qword [temp_epoll_event+epoll_event.data], r9

	mov rax, SYS_EPOLL_CTL
	mov rdi, epoll_fd
	mov rsi, EPOLL_CTL_ADD
	mov rdx, r9
	mov r10, temp_epoll_event
	syscall

	coroutine_yield
	jmp listening_coroutine

struc handle_socket_scratch
	.fd: resq 1
endstruc

handle_socket:
	mov r9, [rbp+coroutine.scratch+handle_socket_scratch.fd]

	mov rax, SYS_READ
	mov rdi, r9
	mov rsi, buffer
	mov rdx, buffer_len
	syscall

	mov rax, SYS_WRITE
	mov rdi, r9
	mov rsi, msg
	mov rdx, len
	syscall

	mov rax, SYS_CLOSE
	mov rdi, r9
	syscall

	coroutine_yield

_start:
	mov rax, SYS_SOCKET
	mov rdi, PF_INET     ; family
	mov rsi, SOCK_STREAM ; type
	mov rdx, IPPROTO_IP  ; protocol
	syscall

	mov dword [optval], 1 ; true

	mov rax, SYS_SETSOCKOPT
	mov rdi, listening_fd ; fd
	mov rsi, SOL_SOCKET   ; level
	mov rdx, SO_REUSEADDR ; optname
	lea r10, [optval]     ; optval
	mov r8, optlen        ; optlen
	syscall

	mov rax, SYS_BIND
	mov rdi, listening_fd ; fd
	mov rsi, addr         ; umyaddr
	mov rdx, addr_len     ; addrlen
	syscall

	mov rax, SYS_LISTEN
	mov rdi, listening_fd ; fd
	mov rsi, BACKLOG      ; backlog
	syscall

	; Initialize listening coroutine
	mov qword [coroutines+listening_fd*coroutine.size+coroutine.rip], listening_coroutine

	mov rax, SYS_EPOLL_CREATE
	mov rdi, 1 ; size (ignored, but must be positive)
	syscall

	mov dword [temp_epoll_event+epoll_event.events], EPOLLIN
	mov qword [temp_epoll_event+epoll_event.data], listening_fd

	mov rax, SYS_EPOLL_CTL
	mov rdi, epoll_fd               ; epfd
	mov rsi, EPOLL_CTL_ADD          ; op
	mov rdx, listening_fd           ; fd
	lea r10, [temp_epoll_event]     ; event
	syscall

loop:
	mov rax, SYS_EPOLL_WAIT
	mov rdi, epoll_fd       ; epfd
	mov rsi, events         ; struct epoll_event *events
	mov rdx, MAX_EVENTS     ; maxevents
	mov r10, -1             ; timeout
	syscall

	sal rax, 2
	lea rax, [3*rax]
	; multiply rax by 12

	%if epoll_event.size != 12
		%error "epoll_event.size must be 12"
	%endif

	; rax is now pointing to just past the last epoll event

inner_loop:
	sub rax, epoll_event.size

	%if coroutine.size != 256
		%error "coroutine.size must be 256"
	%endif

	mov rbp, [events+rax+epoll_event.data]
	sal rbp, 8
	add rbp, coroutines
	coroutine_call

	cmp rax, 0
	jne inner_loop

	jmp loop

section .data

addr: dw 2            ; family = AF_INET
      dw 8000         ; port   = 8000
	  db 127, 0, 0, 1 ; addr   = 127.0.0.1
addr_len: equ $-addr+8

msg: db "HTTP/1.1 200 OK", 13, 10, "Host: example.com", 13, 10, 13, 10, "<p>hello</p>"
len: equ $-msg

msg1: db "Before coroutine", 10
len1: equ $-msg1

msg2: db "After coroutine", 10
len2: equ $-msg2

msg3: db "Inside coroutine", 10
len3: equ $-msg3

section .bss

optval: resd 1
optlen: equ $-optval

temp_epoll_event: resb (epoll_event.size)

buffer: resb 1000
buffer_len: equ $-buffer

events: resb (epoll_event.size*MAX_EVENTS)
coroutines: resb (coroutine.size*MAX_COROUTINES)

accept_sockaddr: resb sockaddr.size
accept_addrlen:  resd 1
