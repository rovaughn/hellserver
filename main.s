
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
	.scratch: resb (1024 - 24)
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

%define PF_INET       2
%define SOCK_STREAM   1
%define IPPROTO_IP    0
%define SOL_SOCKET    1
%define EPOLL_CTL_ADD 1
%define EPOLLIN       1
%define STDIN_FILENO  0
%define STDOUT_FILENO 1
%define STDERR_FILENO 2

%define MAX_EVENTS     10
%define MAX_COROUTINES 10

; Jumps into a coroutine whose address is %1.  Sets up its stack so that it will
; return to where it was called.  Coroutine can't use rbp.
%macro coroutine_call 1
	mov rbp, %1

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
	mov rax, SYS_WRITE
	mov rdi, STDOUT_FILENO
	mov rsi, msg3
	mov rdx, len3
	syscall
	coroutine_yield
	jmp listening_coroutine

_start:
	mov rax, SYS_SOCKET
	mov rdi, PF_INET     ; family
	mov rsi, SOCK_STREAM ; type
	mov rdx, IPPROTO_IP  ; protocol
	syscall
	mov r9, rax ; r9 = listening fd

	mov dword [optval], 1

	mov rax, SYS_SETSOCKOPT
	mov rdi, r9         ; fd
	mov rsi, SOL_SOCKET ; level
	mov rdx, 2          ; optname
	lea r10, [optval]   ; optval
	mov r8, 4           ; optlen
	syscall

	mov rax, SYS_BIND
	mov rdi, r9       ; fd
	mov rsi, addr     ; umyaddr
	mov rdx, addr_len ; addrlen
	syscall

	mov rax, SYS_LISTEN
	mov rdi, r9 		; fd
	mov rsi, 5  		; backlog
	syscall

	; Initialize listening coroutine
	mov qword [coroutines+3*coroutine.size+coroutine.rip], listening_coroutine

	mov rax, SYS_EPOLL_CREATE
	mov rdi, 1                ; size (ignored, but must be positive)
	syscall
	mov r13, rax ; r13 = epoll fd

	mov dword [temp_epoll_event+epoll_event.events], EPOLLIN
	mov qword [temp_epoll_event+epoll_event.data], r9

	mov rax, SYS_EPOLL_CTL
	mov rdi, r13                    ; epfd
	mov rsi, EPOLL_CTL_ADD          ; op
	mov rdx, r9                     ; fd
	lea r10, [temp_epoll_event]     ; event
	syscall

loop:
	mov rax, SYS_EPOLL_WAIT
	mov rdi, r13            ; epfd
	mov rsi, events         ; struct epoll_event *events
	mov rdx, MAX_EVENTS     ; maxevents
	mov r10, -1             ; timeout
	syscall

	; rax contains the number of events
	mov r14, epoll_event_size
	mul r14
	lea r14, [events+rax]
	; now r14 should be events+epoll_event_size*n_events

inner_loop:
	sub r14, epoll_event.size

	mov rax, SYS_WRITE
	mov rdi, STDOUT_FILENO
	mov rsi, msg1
	mov rdx, len1
	syscall

	mov r15, [r14+epoll_event.data]
	sal r15, 10
	coroutine_call (coroutines+3*coroutine.size) ; CHANGE BACK TO coroutines + r15

	mov rax, SYS_WRITE
	mov rdi, STDOUT_FILENO
	mov rsi, msg2
	mov rdx, len2
	syscall

	cmp r14, events

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
temp_epoll_event: resb (epoll_event.size)

buffer: resb 1000
buffer_len: equ $-buffer

events: resb (epoll_event.size*MAX_EVENTS)
coroutines: resb (coroutine.size*MAX_COROUTINES)

