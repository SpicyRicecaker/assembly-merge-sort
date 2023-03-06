; TITLE Sorting Random Floats (Assignment Five)
; Author(s) : Shengdong Li
; Course / Project ID : CS271 / #5 Date: 03 / 06 / 2023
; Description: This program randomly generates some amount of numbers specified
; by the user, within a certain range. It then sorts this array of numbers and
; prints it out.

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
		push 	EDX
		mov 	EDX, OFFSET string
		call 	WriteString
		pop 	EDX
endm


.data
	MIN EQU 10
	MAX EQU 200
	LO 	EQU 100
	HI 	EQU 999

	userIn DWORD ?
.code

; greets the user with program title and author
introduction proc
	print 	"Sorting Random Floats by Shengdong Li."
	call 	crlf
	print 	"This program randomly generates some amount of numbers specified by the user, within a certain range. It then sorts this array of numbers and prints it out."
	ret
introduction endp

; prints the top x values of the stack
; receives: num_to_display (val)
NUM_TO_DISPLAY EQU [EBP+8]
dumpStack proc
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
	;; end prologue   ;;
	mov ecx, NUM_TO_DISPLAY

	print "--stack start--"
	call crlf
	mov esi, ebp
	add esi, 12
	
	loopStart:
		mov 	eax, [esi]
		call 	WriteDec
		call crlf

		add 	esi, 4
		loop 	loopStart

	print "--stack end--"
	call crlf
	;; begin epilogue ;;
	popad
	pop ebp
	;; end epilogue   ;;
	ret 
dumpStack endp


USER_IN_REF EQU [EBP + 8]
; gets an integer from the user.
; receives: userIn (ref) ; in reverse order
getData proc
	;; begin prologue ;;
	push	ebp
	mov 	ebp, esp
	pushad
	;; end prologue   ;;

	jmp body

	invalid: 
		print "Invalid Input."

	body: 
		print "How many numbers should be generated? [10 .. 200]: "

		call ReadInt

		; { make sure data is within range
		cmp 	eax, MIN
		jl		invalid
		
		cmp 	eax, MAX
		jg		invalid
		; }

		mov EDX, USER_IN_REF
		mov [EDX], eax
	;; begin epilogue ;;
	popad
	pop ebp

	;; end epilogue   ;;
	ret 4
getData endp

main proc
	;;;;;;;;;;;;;;;;;;;;
	call introduction
	;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;
	push OFFSET userIn
	call getData

	mov eax, userIn
	call WriteInt
	;;;;;;;;;;;;;;;;;;;;

	invoke exitprocess,0
main endp
end main
