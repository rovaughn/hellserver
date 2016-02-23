
section .text

global _start

; struct sockaddr_in {
; 	uint16_t      sin_family;
;   uint16_t      sin_port;
;   uint32_t      sin_addr;
;   unsigned char __pad[8];
; }

; struct sockaddr {
; 	uint16_t sa_family;
;	char     sa_data[14];
; }

_start:
	mov rax, 41 ; socket
	mov rdi,  2 ; family   = PF_INET
	mov rsi,  1 ; type     = SOCK_STREAM
	mov rdx,  0 ; protocol = IPPROTO_IP
	syscall
	mov r9, rax

	mov dword [rsp-4], 1 ; for optval

	mov rax, 54      ; setsockopt
	mov rdi, r9      ; fd
	mov rsi, 1       ; level = SOL_SOCKET
	mov rdx, 2       ; optname
	lea r10, [rsp-4] ; optval
	mov r8, 4        ; optlen
	syscall

	mov rax, 49       ; bind
	mov rdi, r9       ; fd
	mov rsi, addr     ; umyaddr
	mov rdx, addr_len ; addrlen
	syscall

	mov rax, 50 ; listen
	mov rdi, r9 ; fd
	mov rsi, 5  ; backlog
	syscall

loop:
	mov rax, 43       ; accept
	mov rdi, r9       ; fd
	lea rsi, [rsp-20] ; upeer_sockaddr
	lea rdx, [rsp-4]  ; upeer_addrlen
	syscall
	mov r12, rax

	mov rax, 0          ; read
	mov rdi, r12        ; fd
	mov rsi, buffer     ; buf
	mov rdx, buffer_len ; count
	syscall

	mov rax, 1   ; write
	mov rdi, r12 ; fd
	mov rsi, msg ; buf
	mov rdx, len ; count
	syscall

	mov rax, 3   ; close
	mov rdi, r12 ; fd
	syscall

	jmp loop

section .data

addr: dw 2            ; family = AF_INET
      dw 8000         ; port   = 8000
	  db 127, 0, 0, 1 ; addr   = 127.0.0.1
addr_len: equ $-addr+8

msg: db "HTTP/1.1 200 OK", 13, 10, "Host: example.com", 13, 10, 13, 10, "<p>hello</p>"
len: equ $-msg

section .bss

buffer: resb 1000
buffer_len: equ $-buffer

