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
	; this is a buffer array that we need for merge sort
	buf 		DWORD MAX DUP(?)

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
	ret 4
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
	ret 	0
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
	ret	8
fillArray endp

; This function prints out all the floating point numbers in an array
; Receives: array (ref), arraySize (val), labelArr (ref); push in reverse order
A			EQU [EBP+8]
ARRAY_SIZE 	EQU [EBP+12]
LABEL_ARR	EQU [EBP+16]
displayList proc
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
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
	popad
	pop		ebp
	;; end epilogue   ;;
	ret		12
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

	; { setting eax to array_size/2
	mov 	eax, ARRAY_SIZE
	mov 	ebx, 2
	cdq
	div 	ebx
	cmp 	edx, 0
	; } 
	je 		case0

	jmp 	case1

	case0:
		dec		eax
		mov 	LEFT, eax
		inc 	eax
		mov 	RIGHT, eax

		mov 	eax, LEFT
		mov		ebx, 4
		mul		ebx

		fld 	DWORD PTR [esi+eax]

		mov 	eax, RIGHT
		mov		ebx, 4
		mul		ebx

		fld 	DWORD PTR [esi+eax]

		fadd

		mov 	eax, 2
		push	eax
		fild 	DWORD PTR [esp]
		pop 	eax

		fdiv

		print  	"median: "
		call 	WriteFloat
		call 	crlf

		fstp 	st(0)
		jmp 	endcase

	case1:
		mov		ebx, 4
		mul		ebx

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
	ret		8
displayMedian endp

; This function sorts an array requring 2n of space using merge sort.
; The very basic pseudocode and concepts were learned by me from the book "Algorithms, 4th Edition", a year ago.
; Receives: array (ref), arraySize (val), buffer (ref, assumed to be same size as array), p (val), q (val)
; Returns: VOID!!
A 			EQU [EBP+8]
ARRAY_SiZE 	EQU [EBP+12]
BUFFER 		EQU [EBP+16]
P 			EQU [EBP+20]
Q 			EQU [EBP+24]
R 			EQU [EBP-4]
FINAL_SIZE	EQU [EBP-8]
I			EQU [EBP-12]
J			EQU [EBP-16]
K			EQU [EBP-20]
LEFT_SIZE 	EQU [EBP-24]
RIGHT_SIZE 	EQU [EBP-28]
LEFT 		EQU [EBP-32]
RIGHT 		EQU [EBP-36]
sortList proc
	;; begin prologue ;;
	push 	ebp
	mov 	ebp, esp
	pushad
	sub 	esp, 4
	;; end prologue   ;;

	; { if p == q return 
	mov 	eax, P
	cmp 	eax, Q
	jge		cleanup
	; }

	; { declare r = ((p+q)/2)
	add 	eax, Q
	mov 	ebx, 2
	cdq
	div 	ebx
	mov 	R, eax

	; call sort (p, r)
	push 	R
	push 	P
	push 	BUFFER
	push 	ARRAY_SIZE
	push 	A
	call 	sortList
	; call sort (r+1, q)
	push 	Q
	mov 	eax, R
	add 	eax, 1
	push 	eax
	push 	BUFFER
	push 	ARRAY_SIZE
	push 	A
	call 	sortList

	; size = q - r + 1
	add 	eax, Q
	add 	eax, 1
	sub 	eax, R
	mov 	FINAL_SIZE, eax

	; i, j, k = 0
	mov 	eax, 0
	mov 	I, eax
	mov 	J, eax
	mov 	K, eax

	; left size = r - p + 1
	mov 	eax, R
	add 	eax, 1
	sub 	eax, P
	mov 	LEFT_SIZE, eax
	; right size = q - r 
	mov 	eax, Q
	sub 	eax, R
	mov 	RIGHT_SIZE, eax

	; { copy into B, A [p, q]
	mov 	ecx, FINAL_SIZE
	mov 	esi, BUFFER
	mov 	edx, A
	copyStart:
		mov 	ebx, [edx]
		mov 	[esi], ebx
		add 	esi, 4
		add 	edx, 4
		loop 	copyStart
	; }

	; left = A [p, r]
	mov 	eax, P
	mov 	ebx, 4
	mul 	ebx
	add 	eax, BUFFER
	mov 	LEFT, eax

	; right = A [r+1, q]
	mov 	eax, R
	add 	eax, 1
	mov 	ebx, 4
	mul 	ebx
	add 	eax, BUFFER
	mov 	RIGHT, eax

	; while i < size && j < left_size and k < left_size
	loopStart:
		mov 	eax, I
		cmp 	eax, FINAL_SIZE
		je 		emptyArrays

		mov 	eax, J
		cmp 	eax, LEFT_SIZE
		je 		emptyArrays

		mov 	eax, K
		cmp 	eax, RIGHT_SIZE
		je 		emptyArrays
		; if right[j] < left[k]
		
		mov 	eax, J
		mov 	ebx, 4
		mul 	ebx
		add 	eax, LEFT

		; ;;;;;;;;;;;;;;;;;;;;
		; push 	OFFSET sorted
		; push 	LEFT_SIZE
		; push 	eax
		; call 	displayList
		; ;;;;;;;;;;;;;;;;;;;;

		push	[eax]
		fld 	DWORD PTR [esp]  ; temporarily store left[j] as st(0)
		pop		eax

		; print "THIS IS LEFT"
		; call	WriteFloat

		mov 	eax, K
		mov 	ebx, 4
		mul 	ebx
		add 	eax, RIGHT ; right[k] is eax

		; ;;;;;;;;;;;;;;;;;;;;
		; push 	OFFSET sorted
		; push 	RIGHT_SIZE
		; push 	eax
		; call 	displayList
		; ;;;;;;;;;;;;;;;;;;;;
		
		push	[eax]
		fld 	DWORD PTR [esp]  ; now right is st(0)
		pop		eax

		; print "THIS IS RIGHT"
		; call	WriteFloat

		fcom 	; compares st(0) (right) with st(1) (left)
		; this section is copied straight from the irvine textbook, illegally difficult ec for what? 
		fnstsw	ax ; ; move status word into AX
		sahf ; copy AH into EFLAGS
		jnb     leftLessThanRight
		jmp		rightLessThanLeft
			leftLessThanRight:
				; A [p+i] = left[j]
				; recall that left[j] is currently st(0)

				; Calculate OFFSET A[p+i]
				mov 	eax, I
				add 	eax, P
				mov 	ebx, 4
				mul 	ebx
				add 	eax, A

				; A[p+i] = left[j]
				; remove right
				fstp	st(0)
				; put left
				fstp	DWORD PTR [eax]

				; i += 1
				; j += 1
				mov 	eax, 1
				add 	I, eax
				add 	J, eax

				jmp endRightLeftComp

			; else
			rightLessThanLeft:
				; A[p+i] = right[k]

				; calcualte A[p+i]
				mov 	eax, I
				add 	eax, P
				mov 	ebx, 4
				mul 	ebx
				add 	eax, A

				; set A[p+i] = right[k]
				fstp	DWORD PTR [eax]
				fstp	st(0)

				; i += 1
				; k += 1
				mov 	eax, 1
				add 	I, eax
				add 	K, eax
			endRightLeftComp:
		jmp loopStart

	emptyArrays:
		; for j in j..leftsize
		emptyLeftStart:
			mov 	eax, J
			cmp 	eax, LEFT_SIZE
			jge  	emptyLeftEnd

			; A[p+i] = left[j]

			; first calculate left[j]
			mov 	eax, J
			mov 	ebx, 4
			mul 	ebx
			add 	eax, LEFT
			; store in edx for now
			mov 	edx, [eax]

			; now calculate a[p+i]
			mov 	eax, I
			add 	eax, P
			mov 	ebx, 4
			mul 	ebx
			add 	eax, A
			; now [eax] is A

			mov 	[eax], edx

			; i += 1
			; j += 1
			mov 	eax, 1
			add 	I, eax
			add 	J, eax

			jmp emptyLeftStart
		emptyLeftEnd:

		; for k in k..rightsize
		emptyRightStart:
			mov 	eax, K
			cmp 	eax, RIGHT_SIZE
			jge  	emptyRightEnd

			; A[p+i] = right[k]

			; first calculate right[k]
			mov 	eax, K
			mov 	ebx, 4
			mul 	ebx
			add 	eax, RIGHT
			; store in edx for now
			mov 	edx, [eax]

			; now calculate A[p+i]
			mov 	eax, I
			add 	eax, P
			mov 	ebx, 4
			mul 	ebx
			add 	eax, A
			; now [eax] is A

			mov 	[eax], edx

			; i += 1
			; k += 1
			mov 	eax, 1
			add 	I, eax
			add 	K, eax

			jmp emptyRightStart
		emptyRightEnd:

	;; begin epilogue ;;
	cleanup: 
	add 	esp, 4
	popad
	pop 	ebp
	;; end epilogue   ;;
	ret	 	20
sortList endp


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
	mov 	eax, arraySize
	dec 	eax
	push 	eax ; q
	mov 	eax, 0
	push 	eax ; p
	push 	OFFSET buf
	push 	arraySize
	push 	OFFSEt array
	call 	sortList
	;;;;;;;;;;;;;;;;;;;;

	;;;;;;;;;;;;;;;;;;;;
	push 	OFFSET sorted
	push 	arraySize
	push 	OFFSET array
	call 	displayList
	;;;;;;;;;;;;;;;;;;;;

	;; CALL THIS AFTER SORTING THE ARRAY
	;;;;;;;;;;;;;;;;;;;;
	push 	arraySize
	push 	OFFSET array
	call 	displayMedian
	;;;;;;;;;;;;;;;;;;;;

	invoke 	exitprocess,0
main endp
end main
