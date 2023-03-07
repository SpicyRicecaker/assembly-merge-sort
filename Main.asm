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
	MIN 		EQU 1
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

	print "--begin list--"
	call crlf

	mov 	edx, LABEL_ARR
	call 	WriteString

	mov		ecx, ARRAY_SIZE
	mov 	eax, 0
	mov 	esi, A

	next:
		push 	eax
		mov 	ebx, 10
		cdq
		div 	ebx
		pop 	eax

		cmp 	edx, 0
		jne		noNewLine

		call 	crlf

		noNewLine: 

		; { now esi + eax will give the array element.
		fld 	DWORD PTR [esi]
		call 	WriteFloat
		; MAKE SURE THIS IS HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		fstp	st(0)
		; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		print 	9
		; } 
		inc 	eax
		add 	esi, 4
	loop	next

	call crlf
	print "--end list--"
	call crlf

	;; begin epilogue ;;
	add 	esp, 20
	popad
	pop		ebp
	;; end epilogue   ;;
	ret
displayList endp

; Prints out the median of a list of SORTED floats.
; Receives: array (ref), array_size (val); push these in reverse order
A 			EQU	[EBP+8]
ARRAY_SIZE 	EQU	[EBP+12]
LEFT		EQU [EBP-4]
RIGHT		EQU [EBP-8]
displayMedian proc
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
	sub	 	esp, 8
	;; end prologue   ;;

	mov 	esi, A

	mov 	eax, ARRAY_SIZE
	mov 	ebx, 2
	cdq
	div 	ebx
	cmp 	edx, 0
	je 		case0

	jmp 	case1

	case0:
		mov 	LEFT, eax
		inc 	eax
		mov 	RIGHT, eax

		mov 	eax, 0

		fld 	DWORD PTR [esi+LEFT]
		fld 	DWORD PTR [esi+RIGHT]
		fadd

		mov 	eax, 2
		fild 	DWORD PTR [esp]
		pop 	eax

		fdiv

		print  	"median: "
		call 	WriteFloat
		call 	crlf

		fstp 	st(0)
		jmp 	endcase

	case1:
		fld 	DWORD PTR [esi+eax]

		print  	"median: "
		call 	WriteFloat
		call 	crlf

		fstp 	st(0)

	endcase: 

	;; begin prologue ;;
	add 	esp, 8
	popad
	pop 	ebp
	;; end prologue   ;;
	ret
displayMedian endp


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

	;;;;;;;;;;;;;;;;;;;;
	push 	arraySize
	push 	OFFSET array
	call 	displayMedian
	;;;;;;;;;;;;;;;;;;;;

	invoke 	exitprocess,0
main endp
end main
