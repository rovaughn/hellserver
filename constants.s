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
%define EPOLLOUT      4
%define EPOLLET       (1<<31)
%define STDIN_FILENO  0
%define STDOUT_FILENO 1
%define STDERR_FILENO 2
%define AF_INET       2

%endif

