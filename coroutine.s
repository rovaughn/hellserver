%ifndef coroutine_included
%define coroutine_included

%ifndef coroutine_size
	%define coroutine_size 256
%endif

;struc coroutine
;	.rip:     resq 1
;	.ret:     resq 1
;	.scratch: resb 256
;	.size:
;endstruc

struc coroutin
.rip: resq 1
.ret: resq 1
.scratch: resb (coroutine_size - 16)
.size:
endstruc

; Jumps into a coroutine whose address is %1.  Sets up its stack so that it will
; return to where it was called.  Coroutine can't use rbp.
%macro coroutine_call 0
	; Set the return address.
	mov qword [rbp + coroutin.ret], %%after

	; Jump
	jmp [rbp + coroutin.rip]
%%after:
%endmacro

%macro coroutine_yield 0
	mov qword [rbp + coroutin.rip], %%after
	jmp [rbp + coroutin.ret]
%%after:
%endmacro

%endif

