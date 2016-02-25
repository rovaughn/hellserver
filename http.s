; Facilities for dealing with HTTP.

%define sp   32
%define ht    9
%define cr   13
%define lf   10
%define crlf cr,lf

; HTTP/1.1 standard is given here: https://tools.ietf.org/html/rfc2616

; CTL = any character 0-31 or 127
; token = at least one of any character except CTLs or separators
; SP = space
; HT = horizontal tab
; separators = '()<>@,;:\"/[]?={}' SP and HT
; Method = token
; Request-Line = Method SP Request-URI SP HTTP-Version CRLF
; Request-URI = "*" | absolute-uri | abs-path | authority
; absolute-uri = URI
; abs-path     = path
; authority    = hostname ":" port
; http_uri     = "http://" host [ ":" port ] [ abs_path [ "?" query ]]
; abs_path     = zero or more pchar
; pchar        = unreserved | pct-encoded | sub-delims | ":" | "@"
; pct-encoded  = "%" hexdig hexdig
; unreserved   = alpha | digit | [-._~]
; sub-delims   = [!$&'()*+,;=]

; Parsing routines
; ----------------
; A parsing routine takes the string in rdi and the maximum length in rcx.
; After parsing, rdi is changed to be the new string, with ecx appropriately
; reduced.  If parsing succeeded, rax will be 0, otherwise nonzero.

; TODO:
; alternative approach: pass a label to jump to on error vs on success.

section .data

; Bitfield to determine separators.  Assumes 32 was subtracted from the
; character.  12 bytes.
separators: db 0hfa,0h6c,0hff,0h03,0hfe,0hff,0hff,0hc7,0hff,0hff,0hff,0h57

section .text

space:
	cmp rcx, 1
	jl .bad

	cmp byte [rdi], sp
	jne .bad

	mov rax, 0
	inc rdi
	dec rcx
	ret

.bad:
	mov rax, 1
	ret

endline:
	cmp rcx, 2
	jl .bad

	;cmp word [rdi], (cr<<8 | lf)
	cmp word [rdi], 0h0a0d
	jne .bad

	mov rax, 0
	add rdi, 2
	sub rcx, 2
	ret

.bad:
	mov rax, 1
	ret

; Clobbers: bl
token_char:
	cmp rcx, 1
	jl .bad

	mov eax, 0 ; make sure all of eax is cleared for later
	mov al, [rdi]
	cmp al, 32
	jl .bad

	; Here we know it is >=32
	cmp al, 127
	jge .bad

	mov rbx, rcx ; Save rcx cause we'll need cl for the shift.

	; Now we'll see if it's a separator
	;  (separators[al >> 3] >> (al & 0x07)) & 0x01
	sub al, 32
	mov cl, al
	sar al, 3
	mov al, [separators + eax]
	and cl, 0x07
	sar al, cl
	and al, 0x01
	mov rcx, rbx ; restore rcx
	cmp al, 1    ; 1 in the bit field indicates it is not a separator.
	jne .bad

	; It's valid
	inc rdi
	dec rcx
	mov rax, 0
	ret

.bad:
	mov rax, 1
	ret

; token = one or more ascii characters except CTL or separators
token:
	call token_char
	cmp rax, 0
	jne .bad

.loop:
	call token_char
	cmp rax, 0
	je .loop

	mov rax, 0
	ret

.bad:
	mov rax, 1
	ret

; request-line = token SP request-uri SP http-version CRLF
;request_line:
;	call token
;	cmp rax, 0
;	jne .bad
;
;	call space
;	cmp rax, 0
;	jne .bad
;
;	call request_uri
;	cmp rax, 0
;	jne .bad
;
;	call http_version
;	cmp rax, 0
;	jne .bad
;
;	call endline
;	cmp rax, 0
;	jne .bad
;
;.bad:
;	mov rax, 1
;	ret

; Inputs:
;   %1 = address of status line.
;   %2 = maximum length of text.
;   %3 = register to put method length.
;   %4 = register to put location of request-target.
;   %5 = register to put length of request-target.
; Conditions:
; Layout of status line:
;   method SP request-target SP HTTP-version CRLF

; request-line state machine
; +-  token-char -+- sp -
;  \_____________/
;
%macro parse_request_status_line 2
%endmacro
