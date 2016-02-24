
%include "constants.s"
%include "coroutine.s"

%use ifunc

%ifndef MAX_EVENTS
	%define MAX_EVENTS     10
%endif

%ifndef MAX_COROUTINES
	%define MAX_COROUTINES 10
%endif

%ifndef BACKLOG
	%define BACKLOG         5
%endif

%ifndef listen_addr
	%define listen_addr 127,0,0,1
%endif

%ifndef listen_port
	%define listen_port 80
%endif

%define listening_fd 3
%define epoll_fd     4

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
	sal rbx, ilog2(coroutin.size)
	mov qword [coroutines+rbx+coroutin.rip], handle_conn
	mov qword [coroutines+rbx+coroutin.scratch], r9

	mov dword [temp_epoll_event+epoll_event.events], EPOLLIN | EPOLLOUT
	mov qword [temp_epoll_event+epoll_event.data], r9

	mov rax, SYS_EPOLL_CTL
	mov rdi, epoll_fd
	mov rsi, EPOLL_CTL_ADD
	mov rdx, r9
	mov r10, temp_epoll_event
	syscall

	coroutine_yield
	jmp listening_coroutine

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
	mov qword [coroutines+listening_fd*coroutin.size+coroutin.rip], listening_coroutine

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

	mov qword [rsp - 8], rax

	mov rbp, [events+rax+epoll_event.data]
	sal rbp, ilog2(coroutine_size)
	add rbp, coroutines
	coroutine_call

	mov rax, [rsp - 8]
	cmp rax, 0
	jne inner_loop

	jmp loop

section .data

addr: dw AF_INET
      dw listen_port
	  db listen_addr
	  dq 0           ; padding
addr_len: equ $-addr

section .bss

optval: resd 1
optlen: equ $-optval

buffer: resb 1000
buffer_len: equ $-buffer

events: resb (epoll_event.size*MAX_EVENTS)
coroutines: resb (coroutin.size*MAX_COROUTINES)

temp_epoll_event: resb (epoll_event.size)

accept_sockaddr: resb sockaddr.size
accept_addrlen:  resd 1

