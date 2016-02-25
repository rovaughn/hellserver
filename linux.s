%ifndef constants_included
%define constants_included

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

%define SYS_ACCEPT        43
%define SYS_BIND          49
%define SYS_CLONE         56
%define SYS_CLOSE          3
%define SYS_EPOLL_CREATE 213
%define SYS_EPOLL_CTL    233
%define SYS_EPOLL_WAIT   232
%define SYS_LISTEN        50
%define SYS_READ           0
%define SYS_SETSOCKOPT    54
%define SYS_SOCKET        41
%define SYS_WRITE          1

%define AF_INET       2
%define EPOLLET       (1<<31)
%define EPOLLIN       1
%define EPOLLOUT      4
%define EPOLL_CTL_ADD 1
%define IPPROTO_IP    0
%define PF_INET       2
%define SOCK_STREAM   1
%define SOL_SOCKET    1
%define SO_REUSEADDR  2
%define STDERR_FILENO 2
%define STDIN_FILENO  0
%define STDOUT_FILENO 1

; for linux/ia64:
; int clone(
; 	int               flags,
; 	void             *child_stack_base,
; 	size_t            stack_size,
; 	pid_t             ptid,
; 	pid_t            *ctid,
; 	struct user_desc *tls
; );

%define CLONE_THREAD 0x00010000

; int __clone(int (*)(void *), void *, int, void *, ...);

; .text
; .global __clone
; .type   __clone,@function
; __clone:
; 	xor %eax,%eax     xor eax, eax
; 	mov $56,%al       mov  al,  56
; 	mov %rdi,%r11     mov r11, rdi
; 	mov %rdx,%rdi     mov rdi, rdx
; 	mov %r8,%rdx      mov rdx,  r8
; 	mov %r9,%r8       mov  r8,  r9
; 	mov 8(%rsp),%r10  mov r10, [8+rsp]
; 	mov %r11,%r9      mov  r9, r11
; 	and $-16,%rsi     mov rsi, $-16
; 	sub $8,%rsi       sub rsi, 8
; 	mov %rcx,(%rsi)   mov [rsi], rcx
; 	syscall           syscall
; 	test %eax,%eax    test eax, eax
; 	jnz 1f            jnz 1f
; 	xor %ebp,%ebp     xor ebp, ebp
; 	pop %rdi          pop rdi
; 	call *%r9         call [r9]
; 	mov %eax,%edi     mov edi, eax
; 	xor %eax,%eax     xor eax, eax
; 	mov $60,%al       mov al,   60
; 	syscall           syscall
; 	hlt               hlt
; 1:	ret           ret


%endif

