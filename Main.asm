; TITLE Assignment X
; Author(s) : XX XX
; Course / Project ID : / #X Date: xx / xx / 20xx
; Description: An example program.

INCLUDE Irvine32.inc

.386
.model flat, stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword

; WriteString wrapper
; Takes in a constant byte string and prints it out. Very handy!
print macro data:REQ
	local string
	.data
		string BYTE data, 0
	.code
		push EDX
		mov EDX, OFFSET string
		call WriteString
		pop EDX
endm

.data
.code
main proc
	print "hello world"
	invoke exitprocess,0
main endp
end main
