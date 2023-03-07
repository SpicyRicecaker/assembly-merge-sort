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
	MIN 		EQU 10
	MAX 		EQU 200
	LO 			EQU 100
	HI 			EQU 999

	userIn 		DWORD ?
	arraySize 	DWORD ? 
	; since we know that the maximum user input is 200, we preset the array size to 200
	array 		DWORD MAX DUP(?)

	unsorted 	BYTE "unsorted:",0
	sorted 		BYTE "sorted:",0
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
		call crlf

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

; This function generates a float between a certain range of integers defined as a constant
; Receives: n (val) ; a dummy value.
; Returns: n (val) ; a 32-bit float
N EQU [EBP + 8]
; LOCAL_NUM_OF_NUMS EQU [ESP - 4]
generate proc 
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
	sub		esp, 4
	;; end prologue   ;;


	mov 	eax, 1000000000 ; 1 billion
	call 	RandomRange

	; need to first put eax into stack location, then load its location
	push	eax
	fild	DWORD PTR [esp]
	pop		eax

	mov 	eax, 1000000000
	push	eax
	fild 	DWORD PTR [esp]
	pop		eax

	fdiv

	mov 	eax, HI
	sub 	eax, LO
	add 	eax, 1
	push	eax
	fild 	DWORD PTR [esp]
	pop		eax

	fmul

	push	LO
	fild 	DWORD PTR [esp]
	pop		eax

	fadd 	
	
	fstp 	DWORD PTR N

	;; begin epilogue ;;
	add		esp, 4
	popad
	pop		ebp
	;; end epilogue   ;;
	ret
generate endp 

; This function fills an array with random floats of a certain range
; Receives: array (ref), array_size (val); push in reverse order
A			EQU [EBP + 8]
ARRAY_SIZE	EQU [EBP + 12]
fillArray proc
	;; begin prologue ;;
	push ebp
	mov ebp, esp
	pushad
	;; end prologue   ;;

	mov ecx, ARRAY_SIZE
	mov esi, A

	start:
		;;;;;;;;;;
		push 0
		call generate
		pop edx
		;;;;;;;;;;
		

		mov [esi], edx
		
		add esi, 4
		loop start

	;; begin epilogue ;;
	popad
	pop ebp
	;; end epilogue   ;;
	ret
fillArray endp

; This function prints out all the floating point numbers in an array
; Receives: array (ref), arraySize (val), labelArr (ref); push in reverse order
A			EQU [EBP+8]
ARRAY_SIZE 	EQU [EBP+12]
LABEL_ARR	EQU [EBP+16]
NUM_ROWS	EQU [EBP-4]
Y			EQU [EBP-8]
Y_OFFSET	EQU [EBP-12]
X			EQU [EBP-16]
X_OFFSET	EQU [EBP-20]
displayList proc
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
	sub 	esp, 20
	;; end prologue   ;;
	mov 	edx, LABEL_ARR
	call 	WriteString
	call 	crlf

	; { calculate number of rows we will have
	mov 	eax, ARRAY_SIZE
	mov 	ebx, 10
	cdq
	div 	ebx
	mov 	NUM_ROWS, eax
	; }

	; reset & prime our variables
	mov		eax, 0
	mov 	X, eax ; set x to 0
	mov 	esi, A ; set esi to A

	mov 	ecx, NUM_ROWS ; iterate by the number of rows we have to print
	nextInColumn:
		mov 	edx, 0

		; { reset y
		mov 	eax, 0
		mov 	Y, eax
		; } 

		; { calculate the X_OFFSET, which is simple cause it's just x * 4
		mov		eax, X
		mov		ebx, 4
		mul		ebx
		mov		X_OFFSET, eax
		; }

		; create a loop over elements in the row
		push 	ecx
		mov 	ecx, 10
		nextInRow: 
			; { Check if we have any more numbers
			mov		eax, Y
			mov		ebx, NUM_ROWS
			mul		ebx
			add		eax, X
			cmp 	eax, ARRAY_SIZE
			jge		nextInColumnPrelude
			; } 

			; { calculate the Y_OFFSET
			mov		eax, Y
			mov		ebx, NUM_ROWS
			mul		ebx
			mov 	ebx, 4
			mul 	ebx
			mov		Y_OFFSET, eax
			; }

			; { Add the Y_OFFSET to the X_OFFSET
			mov		eax, X_OFFSET
			add		eax, Y_OFFSET
			; } 

			; { now esi + eax will give the array element.
			fld 	DWORD PTR [esi+eax]
			call 	WriteFloat
			print 	9
			; } 

			; { Increment y 
			mov 	eax, Y
			add 	eax, 1
			mov 	Y, eax
			; } 
			loop 	nextInRow

		nextInColumnPrelude:
			pop 	ecx

			call	crlf
		
			mov 	eax, X
			add 	eax, 1
			mov 	X, eax
			;;;
			loop nextInColumn

	;; begin epilogue ;;
	add 	esp, 20
	popad
	pop		ebp
	;; end epilogue   ;;
	ret
displayList endp


main proc
	; Sets the seed according to system clock
	; Setting to 0 for debug purposes
	; call 	Randomize
	finit

	;;;;;;;;;;;;;;;;;;;;
	call 	introduction
	;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;
	push 	OFFSET userIn
	call 	getData
	;;;;;;;;;;;;;;;;;;;;

	mov 	eax, userIn
	mov 	arraySize, eax

	;;;;;;;;;;;;;;;;;;;;
	push 	arraySize
	push 	OFFSET array
	call 	fillArray
	;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;
	push 	OFFSET unsorted
	push 	arraySize
	push 	OFFSET array
	call 	displayList
	;;;;;;;;;;;;;;;;;;;;


	invoke 	exitprocess,0
main endp
end main
