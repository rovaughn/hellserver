; Files for testing the other assembly functions/macros.

%include "http.s"

section .data

_space:   db " "
_endline: db cr, lf
_token:   db "hello "

section .text

global _start

%macro assert 2
	cmp %1, %2
	jne .failure
%endmacro

_start:
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; parse_request_status_line ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	mov rdi, _space
	mov rcx, 1
	call space
	assert rax, 0
	assert rdi, _space+1
	assert rcx, 0

	mov rdi, _endline
	mov rcx, 2
	call endline
	assert rax, 0
	assert rdi, _endline+2
	assert rcx, 0

	mov rdi, _token
	mov rcx, 6
	call token_char
	assert rax, 0
	assert rdi, _token+1
	assert rcx, 5

	mov rdi, _space
	mov rcx, 1
	call token_char
	assert rax, 1
	assert rdi, _space
	assert rcx, 1

	mov rdi, _token
	mov rcx, 6
	call token
	assert rax, 0
	assert rdi, _token+5
	assert rcx, 1

.success:
	mov rax, 60 ; exit
	mov rdi, 0
	syscall

.failure:
	mov rax, 60 ; exit
	mov rdi,  1
	syscall

