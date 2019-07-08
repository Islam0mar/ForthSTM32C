/* Directives */
    .thumb                  @ (same as saying '.code 16')
    .syntax unified
    .section .text
    .cpu cortex-m3
    .fpu softvfp
    .align	1
	.p2align 2,,3
    .include    "stm32f103.i"


@@ Reserve three special registers: 
@@ SP(r13) stack pointer
@@ LR(r14) link register
@@ IP(r12) points to the next forth word that will be executed
@@ PC(r15) interpreter pointer points to the next line of code which will be excuted
@@ PSR program status register
    SR0     .req    r0          @ scratch register
    SR1     .req    r1          @ scratch register
    SR2     .req    r2          @ scratch register
    SR3     .req    r3          @ scratch register
    UP      .req    r4          @ user pointer   
    TOS     .req    r5          @ top of the stack
    RSP     .req    r6          @ return stack pointer
/*    WP      .req    r7          @ word pointer*/
/* NEXT macro. */
	.macro NEXT
	ldr SR0, [IP], #4
    ldr SR1, [SR0]
	bx  SR1
	.endm

/* Macros to deal with the return stack. */
	.macro PUSHRSP reg
	str \reg, [RSP, #-4]!
	.endm

	.macro POPRSP reg
	ldr \reg, [RSP], #4
	.endm

	.macro __key
    ldr SR1, = USART1_SR
    ldr SR0, [SR1]
keyPoll:
    tst SR0, # USART_SR_RXNE        @ Check for reception 
    beq keyPoll                     @ wait for it
    ldr SR0, = USART1_DR
	.endm

/* DOCOL - the interpreter! */
	.text
	.align	1
	.p2align 2,,3
DOCOL:
	PUSHRSP IP		    @@ push IP on to the return stack
	add IP, SR0, #4		@@ SR0 points to codeword, so make
	NEXT

    /* Assembler entry point. */
    .text
	.align	1
	.p2align 2,,3
	.globl main
    .syntax unified
	.thumb
	.thumb_func
	.fpu softvfp
	.type	main, %function
main:
    ldr WR, =var_S0
    str SP, [WR]                    @ Save the original stack position in var_S0
    ldr RSP, =return_stack_top      @ Set the initial return stack position
    bl  ClockInit
    bl	SystemCoreClockUpdate
    bl  set_up_data_segment         @ Set up the data segment
    bl  USART_Init
    ldr IP, =cold_start             @ Make the IP point to cold_start
    NEXT                            @ Start the interpreter

	.section .rodata
cold_start:			// High-level code without a codeword.
	.int QUIT

/*
	BUILT-IN WORDS ----------------------------------------------------------------------

	Remember our dictionary entries (headers)?  Let's bring those together with the codeword
	and data words to see how : DOUBLE DUP + ; really looks in memory.

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+--|---------+------------+------------+
    ^       len                         pad  codeword      |
	   |							  V
	  LINK in next word				points to codeword of DUP
	
	Initially we can't just write ": DOUBLE DUP + ;" (ie. that literal string) here because we
	don't yet have anything to read the string, break it up at spaces, parse each word, etc. etc.
	So instead we will have to define built-in words using the GNU assembler data constructors
	(like .int, .byte, .string, .ascii and so on -- look them up in the gas info page if you are
	unsure of them).

	The long way would be:

	.int <link to previous word>
	.byte 6			// len
	.ascii "DOUBLE"		// string
	.byte 0			// padding
DOUBLE: .int DOCOL		// codeword
	.int DUP		// pointer to codeword of DUP
	.int PLUS		// pointer to codeword of +
	.int EXIT		// pointer to codeword of EXIT

	That's going to get quite tedious rather quickly, so here I define an assembler macro
	so that I can just write:

	defword "DOUBLE",6,,DOUBLE
	.int DUP,PLUS,EXIT

	and I'll get exactly the same effect.

	Don't worry too much about the exact implementation details of this macro - it's complicated!
*/

/* Flags - these are discussed later. */
	.set F_IMMED,0x80
	.set F_HIDDEN,0x20
	.set F_LENMASK,0x1f	// length mask

	// Store the chain of links.
	.set link,0

	.macro defword name, namelen, flags=0, label
	.section .rodata
	.align	1
	.p2align 2,,3
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align	1
	.p2align 2,,3		// padding to next 4 byte boundary
	.globl \label
\label :
	.int DOCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

/*
	Similarly I want a way to write words written in assembly language.  There will quite a few
	of these to start with because, well, everything has to start in assembly before there's
	enough "infrastructure" to be able to start writing FORTH words, but also I want to define
	some common FORTH words in assembly language for speed, even though I could write them in FORTH.

	This is what DUP looks like in memory:

	  pointer to previous word
	   ^
	   |
	+--|------+---+---+---+---+------------+
	| LINK    | 3 | D | U | P | code_DUP ---------------------> points to the assembly
	+---------+---+---+---+---+------------+		    code used to write DUP,
    ^       len              codeword			    which ends with NEXT.
	   |
	  LINK in next word

	Again, for brevity in writing the header I'm going to write an assembler macro called defcode.
	As with defword above, don't worry about the complicated details of the macro.
*/

	.macro defcode name, namelen, flags=0, label
	.section .rodata
	.align	1
	.p2align 2,,3
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align	1
	.p2align 2,,3		// padding to next 4 byte boundary
	.globl \label
\label :
	.int code_\label	// codeword
	.text
	.align	1
	.p2align 2,,3
	.globl code_\label
code_\label :			// assembler code follows
	.endm

/*
	Now some easy FORTH primitives.  These are written in assembly for speed.  If you understand
	i386 assembly language then it is worth reading these.  However if you don't understand assembly
	you can skip the details.
*/

	defcode "DROP",4,,DROP
	pop {SR0}		@ drop top of stack
	NEXT

	defcode "SWAP",4,,SWAP
	pop {SR0}       @ swap top two elements on stack
	pop {SR1}
	push {SR0}
	push {SR1}
	NEXT

	defcode "DUP",3,,DUP
	ldr SR0, [SP]   @ (  ) , SR0 = a
    push {SR0}        @ ( a a  ) , SR0 = a
    NEXT		    @ duplicate top of stack

	defcode "OVER",4,,OVER
	@@ ( a b c) SR0 = b we take the element at DSP + 4
    @@ and since DSP is the top of the stack we will load
    @@ the second element of the stack in SR0
    ldr SR0, [SP, #4]
    push {SR0}         @ ( a b c b )
    NEXT

@@ ROT ( a b c -- b c a) rotation

    defcode "ROT",3,,ROT
    pop {SR0}          @ ( a b ) SR0 = c
    pop {SR1}          @ ( a ) SR1 = b
    pop {SR2}          @ ( ) SR2 = a
    push {SR1}         @ ( b )
    push {SR0}         @ ( b c )
    push {SR2}         @ ( b c a )
    NEXT	
	
	defcode "-ROT",4,,NROT
    pop {SR0}          @ ( a b ) SR0 = c
    pop {SR1}          @ ( a ) r1 = b
    pop {SR2}          @ ( ) r2 = a
    push {SR0}         @ ( c )
    push {SR2}         @ ( c a )
    push {SR1}         @ ( c a b )
    NEXT

	defcode "2DROP",5,,TWODROP // drop top two elements of stack
	pop {SR0}
	pop {SR0}
	NEXT

	defcode "2DUP",4,,TWODUP // duplicate top two elements of stack
	ldr SR0, [SP]   @ (  ) , SR0 = a
    push {SR0}        @ ( a  ) , SR0 = a
    push {SR0}        @ ( a a  ) , SR0 = a
	NEXT

	defcode "2SWAP",5,,TWOSWAP // swap top two pairs of elements of stack
	pop {SR0}
	pop {SR1}
	pop {SR2}
	pop {SR3}
	push {SR1}
	push {SR0}
	push {SR3}
	push {SR2}
	NEXT

	defcode "?DUP",4,,QDUP	// duplicate top of stack if non-zero
    ldr SR0, [SP]   @ SR0 = x
    cmp SR0, #0     @ test if x==0
    beq 1f          @ if x==0 we jump to 1
    push {SR0}        @ ( a a ) it's now duplicated
    1: NEXT         @ ( a a / 0 )

    defcode "1+",2,,INCR
    pop {SR0}              // increment top of stack
    add SR0,SR0,#1
    push {SR0}
    NEXT
    
    defcode "1-",2,,DECR
    pop {SR0}
    sub SR0,SR0,#1
    push {SR0}
    NEXT

    defcode "4+",2,,INCR4
    pop {SR0}
    add SR0,SR0,#4
    push {SR0}
    NEXT

    defcode "4-",2,,DECR4
    pop {SR0}
    sub SR0,SR0,#4
    push {SR0}
    NEXT

    defcode "+",1,,ADD
    pop {SR0}
    pop {SR1}
    add SR0,SR0,SR1
    push {SR0}
    NEXT


    defcode "-",1,,SUB
    pop {SR1}
    pop {SR0}
    sub SR0,SR0,SR1
    push {SR0}
    NEXT


    defcode "*",1,,MUL
    pop {SR0}
    pop {SR1}
    mul SR0,SR0,SR1
    push {SR0}
    NEXT

    defcode "/",1,,DIV
	pop {SR1}
	pop {SR0}
	UDIV SR0,SR0,SR1
    push {SR0}		    @ push quotient
	NEXT

/*
	In this FORTH, only /MOD and U/MOD is primitive.  Later we will define the /, MOD and other words in
	terms of the primitives /MOD and U/MOD.  The design of the i386 assembly instructions idiv and div which
	leave both quotient and remainder makes this the obvious choice.
*/

	defcode "/MOD",4,,DIVMOD
	pop {SR1}
	pop {SR0}
	SDIV SR2,SR0,SR1
    MUL SR1,SR1,SR2
    sub SR1,SR0,SR1
	push {SR1}		    @ push remainder
    push {SR2}		    @ push quotient
    NEXT

	defcode "U/MOD",5,,UDIVMOD
	pop {SR1}
	pop {SR0}
	UDIV SR2,SR0,SR1
    MUL SR1,SR1,SR2
    sub SR1,SR0,SR1
	push {SR1}		    @ push remainder
    push {SR2}		    @ push quotient
	NEXT

/*
	Lots of comparison operations like =, <, >, etc..

	ANS FORTH says that the comparison words should return all (binary) 1's for
	TRUE and all 0's for FALSE.  This is a bit of a strange convention for C
	programmers ...
	Anyway, -1 meaning TRUE and 0 meaning FALSE.
*/
@ = ( a b | p ) where p is 1 when a and b are equal (0 otherwise)

    defcode "=",1,,EQU	// top two words are equal?
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    moveq SR0, #1
    movne SR0, #0
    push {SR0}
    NEXT

	defcode "<>",2,,NEQU	// top two words are not equal?
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    movne SR0, #1
    moveq SR0, #0
    push {SR0}
    NEXT

	defcode "<",1,,LT
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    movlt SR0, #1
    movge SR0, #0
    push {SR0}
    NEXT

	defcode ">",1,,GT
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    movgt SR0, #1
    movle SR0, #0
    push {SR0}
    NEXT

	defcode "<=",2,,LE
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    movle SR0, #1
    movlt SR0, #0
    push {SR0}
    NEXT

	defcode ">=",2,,GE
	pop {SR1}
    pop {SR0}
    cmp SR0, SR1
    movle SR0, #1
    movgt SR0, #0
    push {SR0}
    NEXT

	defcode "AND",3,,AND	// bitwise AND
	pop {SR0}
    pop {SR1}
    and SR0, SR1, SR0
    push {SR0}
    NEXT

	defcode "OR",2,,OR	// bitwise OR
	pop {SR0}
    pop {SR1}
    orr SR0, SR1, SR0
    push {SR0}
    NEXT

	defcode "XOR",3,,XOR	// bitwise XOR
	pop {SR0}
    pop {SR1}
    eor SR0, SR1, SR0
    push {SR0}
    NEXT

	defcode "INVERT",6,,INVERT // this is the FORTH bitwise "NOT" function (cf. NEGATE and NOT)
	pop {SR0}
    mvn SR0, SR0
    push {SR0}
    NEXT
	NEXT

	defcode "EXIT",4,,EXIT
	POPRSP IP	            @ pop return stack into %esi
    NEXT
    
@ LIT is used to compile literals in forth word.
@ When LIT is executed it pushes the literal (which is the next codeword)
@ into the stack and skips it (since the literal is not executable).

    defcode "LIT", 3,, LIT
    ldr SR1, [IP], #4
    push {SR1}
    NEXT
/*
	MEMORY ----------------------------------------------------------------------

	As important point about FORTH is that it gives you direct access to the lowest levels
	of the machine.  Manipulating memory directly is done frequently in FORTH, and these are
	the primitive words for doing it.
*/




@ C! and @! are the same for bytes

    defcode "C!",2,,STOREBYTE
    pop {SR0}
    pop {SR1}
    strb SR1, [SR0]
    NEXT


    defcode "C@",2,,FETCHBYTE
    pop {SR0}
    mov SR1, #0
    ldrb SR1, [SR0]
    push {SR1}
    NEXT

    @ ! ( value address -- ) write value at address
	defcode "!",1,,STORE
    pop {SR0}
    pop {SR1}
    str SR1, [SR0]
    NEXT

	defcode "@",1,,FETCH
	@ @ ( address -- value ) reads value from address
    pop {SR1}
    ldr SR0, [SR1]
    push {SR0}
    NEXT

/* and CMOVE is a block copy operation. */
	defcode "CMOVE",5,,CMOVE
    pop {SR0}
    pop {SR1}
    pop {SR2}
1:
    cmp SR0, #0              @ while length > 0
    ldrbgt SR3, [SR2], #1     @ read character from source
    strbgt SR3, [SR1], #1     @ and write it to dest (increment both pointers)
    subgt SR0, SR0, #1        @ decrement length
    bgt 1b
    NEXT

/*
	BUILT-IN VARIABLES ----------------------------------------------------------------------

	These are some built-in variables and related standard FORTH words.  Of these, the only one that we
	have discussed so far was LATEST, which points to the last (most recently defined) word in the
	FORTH dictionary.  LATEST is also a FORTH word which pushes the address of LATEST (the variable)
	on to the stack, so you can read or write it using @ and ! operators.  For example, to print
	the current value of LATEST (and this can apply to any FORTH variable) you would do:

	LATEST @ . CR

	To make defining variables shorter, I'm using a macro called defvar, similar to defword and
	defcode above.  (In fact the defvar macro uses defcode to do the dictionary header).
*/

	.macro defvar name, namelen, flags=0, label, initial=0
	defcode \name,\namelen,\flags,\label
    ldr SR0, = var_\name
    push {SR0}
	NEXT
	.data
	.align	1
	.p2align 2,,3
var_\name:
	.int \initial
	.endm

/*
	The built-in variables are:

	STATE		Is the interpreter executing code (0) or compiling a word (non-zero)?
	LATEST		Points to the latest (most recently defined) word in the dictionary.
	DP		Points to the next free byte of memory.  When compiling, compiled words go here.
	S0		Stores the address of the top of the parameter stack.
	BASE		The current base for printing and reading numbers.

*/
	defvar "STATE",5,,STATE
	defvar "DP",2,,DP
	defvar "LATEST",6,,LATEST,name_SYSCALL0 // SYSCALL0 must be last in built-in dictionary
	defvar "S0",2,,SZ
	defvar "BASE",4,,BASE,10

/*
	BUILT-IN CONSTANTS ----------------------------------------------------------------------

	It's also useful to expose a few constants to FORTH.  When the word is executed it pushes a
	constant value on the stack.

	The built-in constants are:

	VERSION		Is the current version of this FORTH.
	SR0		The address of the top of the return stack.
	DOCOL		Pointer to DOCOL.
	F_IMMED		The IMMEDIATE flag's actual value.
	F_HIDDEN	The HIDDEN flag's actual value.
	F_LENMASK	The length mask in the flags/len byte.

	SYS_*		and the numeric codes of various Linux syscalls (from <asm/unistd.h>)
*/

//#include <asm-i386/unistd.h>	// you might need this instead
#include <asm/unistd.h>

	.macro defconst name, namelen, flags=0, label, value
	defcode \name,\namelen,\flags,\label
    ldr SR0, = #\value
    push {SR0}
	NEXT
	.endm

	defconst "VERSION",7,,VERSION,PRINTER_VERSION
	defconst "SR0",2,,RZ,return_stack_top
	defconst "DOCOL",5,,__DOCOL,DOCOL
	defconst "F_IMMED",7,,__F_IMMED,F_IMMED
	defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN
	defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK

	defconst "SYS_EXIT",8,,SYS_EXIT,__NR_exit
	defconst "SYS_OPEN",8,,SYS_OPEN,__NR_open
	defconst "SYS_CLOSE",9,,SYS_CLOSE,__NR_close
	defconst "SYS_READ",8,,SYS_READ,__NR_read
	defconst "SYS_WRITE",9,,SYS_WRITE,__NR_write
	defconst "SYS_CREAT",9,,SYS_CREAT,__NR_creat
	defconst "SYS_BRK",7,,SYS_BRK,__NR_brk

	defconst "O_RDONLY",8,,__O_RDONLY,0
	defconst "O_WRONLY",8,,__O_WRONLY,1
	defconst "O_RDWR",6,,__O_RDWR,2
	defconst "O_CREAT",7,,__O_CREAT,0100
	defconst "O_EXCL",6,,__O_EXCL,0200
	defconst "O_TRUNC",7,,__O_TRUNC,01000
	defconst "O_APPEND",8,,__O_APPEND,02000
	defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000

/*
	RETURN STACK ----------------------------------------------------------------------

	These words allow you to access the return stack.  Recall that the register %ebp always points to
	the top of the return stack.
*/

    defcode ">R",2,,TOR
    pop {SR0}
    PUSHRSP SR0
    NEXT

@ R> ( -- a ) move the top element from the return stack to the data stack

    defcode "R>",2,,FROMR
    POPRSP SR0
    push {SR0}
    NEXT

@ RDROP drops the top element from the return stack

    defcode "RDROP",5,,RDROP
    add RSP,RSP,#4
    NEXT

@ RSP@, RSP!, DSP@, DSP! manipulate the return and data stack pointers

    defcode "RSP@",4,,RSPFETCH
    push {RSP}
    NEXT

    defcode "RSP!",4,,RSPSTORE
    pop {RSP}
    NEXT

/*
	PARAMETER (DATA) STACK ----------------------------------------------------------------------


    */
    defcode "DSP@",4,,DSPFETCH
    mov SR0, SP
    push {SR0}
    NEXT

    defcode "DSP!",4,,DSPSTORE
    pop {SR0}
    mov SR0, SP
    NEXT


@ -----------------------------------------------------------------------------
    defcode "KEY",3,,KEY    @ ( -- c ) Receive one character
@ -----------------------------------------------------------------------------
    __key
    push {SR0}
    NEXT
    
@@@ ( c -- )
	defcode "EMIT",4,,EMIT
    pop {SR0}
    ldr SR1, = USART1_SR
    ldr SR1, [SR1]
emitPoll:
    tst SR1, # USART_SR_TXE     @ Check for reception 
    beq emitPoll                @ quit if not
    strb SR0, USART1_DR
	NEXT

/*
	Back to input, WORD is a FORTH word which reads the next full word of input.

	What it does in detail is that it first skips any blanks (spaces, tabs, newlines and so on).
	Then it calls KEY to read characters into an internal buffer until it hits a blank.  Then it
	calculates the length of the word it read and returns the address and the length as
	two words on the stack (with the length at the top of stack).

	Notice that WORD has a single internal buffer which it overwrites each time (rather like
	a static C string).  Also notice that WORD's internal buffer is just 32 bytes long and
	there is NO checking for overflow.  31 bytes happens to be the maximum length of a
	FORTH word that we support, and that is what WORD is used for: to read FORTH words when
	we are compiling and executing code.  The returned strings are not NUL-terminated.

	Start address+length is the normal way to represent strings in FORTH (not ending in an
	ASCII NUL character as in C), and so FORTH strings can contain any character including NULs
	and can be any length.

	WORD is not suitable for just reading strings (eg. user input) because of all the above
	peculiarities and limitations.

	Note that when executing, you'll see:
	WORD FOO
	which puts "FOO" and length 3 on the stack, but when compiling:
	: BAR WORD FOO ;
	is an error (or at least it doesn't do what you might expect).  Later we'll talk about compiling
	and immediate mode, and you'll understand why.
*/

@ WORD ( -- addr length ) reads next word from stdin
@ skips spaces and comments, limited to 32 characters 
	defcode "WORD",4,,WORD
1:
    __key                   @ read a character
    cmp SR0, #'\\'
    beq 3f                  @ skip comments until end of line
    cmp SR0, #' '
    ble 1b                  @ skip blank character

    ldr     SR1, =word_buffer
2:
    strb SR0, [SR6], #1       @ store character in word buffer
    __key                   @ read more characters until a space is found
    cmp SR0, #' '
    bgt 2b

    ldr SR0, =word_buffer    @ r0, address of word
    sub SR1, SR1, SR0          @ r1, length of word

    NEXT
3:
    bl __key                 @ skip all characters until end of line
    cmp r0, #'\n'
    bne 3b
    b 1b

@ word_buffer for WORD
    .data
word_buffer:
    .space 32
    

/*
	As well as reading in words we'll need to read in numbers and for that we are using a function
	called NUMBER.  This parses a numeric string such as one returned by WORD and pushes the
	number on the parameter stack.

	The function uses the variable BASE as the base (radix) for conversion, so for example if
	BASE is 2 then we expect a binary number.  Normally BASE is 10.

	If the word starts with a '-' character then the returned value is negative.

	If the string can't be parsed as a number (or contains characters outside the current BASE)
	then we need to return an error indication.  So NUMBER actually returns two items on the stack.
	At the top of stack we return the number of unconverted characters (ie. if 0 then all characters
	were converted, so there is no error).  Second from top of stack is the parsed number or a
	partial value if there was an error.
*/
    @ NUMBER ( addr length -- n e ) converts string to number
@ n is the parsed number
@ e is the number of unparsed characters

defcode "NUMBER",6,,NUMBER
    pop r1
    pop r0
    push {r4-r6}

    @ Save address of the string.
    mov r2, r0

    @ r0 will store the result after conversion.
    mov r0, #0

    @ Check if length is positive, otherwise this is an error.
    cmp r1, #0
    ble 5f

    @ Load current base.
    ldr r3, =var_BASE
    ldr r3, [r3]

    @ Load first character and increment pointer.
    ldrb r4, [r2], #1

    @ Check trailing '-'.
    mov r5, #0
    cmp r4, #45 @ 45 in '-' en ASCII
    @ Number is positive.
    bne 2f
    @ Number is negative.
    mov r5, #1
    sub r1, r1, #1

    @ Check if we have more than just '-' in the string.
    cmp r1, #0
    @ No, proceed with conversion.
    bgt 1f
    @ Error.
    mov r1, #1
    b 5f
1:
    @ number *= BASE
    @ Arithmetic shift right.
    @ On ARM we need to use an additional register for MUL.
    mul r6, r0, r3
    mov r0, r6

    @ Load the next character.
    ldrb r4, [r2], #1
2:
    @ Convert the character into a digit.
    sub r4, r4, #48 @ r4 = r4 - '0'
    cmp r4, #0
    blt 4f @ End, < 0
    cmp r4, #9
    ble 3f @ chiffre compris entre 0 et 9

    @ Test if hexadecimal character.
    sub r4, r4, #17 @ 17 = 'A' - '0'
    cmp r4, #0
    blt 4f @ End, < 'A'
    add r4, r4, #10
3:
    @ Compare to the current base.
    cmp r4, r3
    bge 4f @ End, > BASE

    @ Everything is fine.
    @ Add the digit to the result.
    add r0, r0, r4
    sub r1, r1, #1

    @ Continue processing while there are still characters to read.
    cmp r1, #0
    bgt 1b
4:
    @ Negate result if we had a '-'.
    cmp r5, #1
    rsbeq r0, r0, #0
5:
    @ Back to the caller.
    pop {r4-r6}
    push r0
    push r1
    NEXT

/*
	DICTIONARY LOOK UPS ----------------------------------------------------------------------

	We're building up to our prelude on how FORTH code is compiled, but first we need yet more infrastructure.

	The FORTH word (FIND) takes a string (a word as parsed by WORD -- see above) and looks it up in the
	dictionary.  What it actually returns is the address of the dictionary header, if it finds it, or 0 if it
	didn't.

	This word is call (FIND) but not simply FIND because FIND is a standard ANS Forth word which does a little
	more than (FIND).

	So if DOUBLE is defined in the dictionary, then WORD DOUBLE (FIND) returns the following pointer:

    pointer to this
	|
	|
	V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+

	See also >CFA and >DFA.

	(FIND) doesn't find dictionary entries which are flagged as HIDDEN.  See below for why.
*/

@ FIND ( addr length -- dictionary_address )
@ Tries to find a word in the dictionary and returns its address.
@ If the word is not found, NULL is returned.

defcode "FIND",4,,FIND
    pop r1              @length
    pop r0              @addr
    push  {r5,r6,r8,r9}         @ save callee save registers
    ldr r2, =var_LATEST
    ldr r3, [r2]                    @ get the last defined word address
1:
    cmp r3, #0                      @ did we check all the words ?
    beq 4f                          @ then exit

    ldrb r2, [r3, #4]               @ read the length field
    and r2, r2, #(F_HIDDEN|F_LENMASK) @ keep only length + hidden bits
    cmp r2, r1                      @ do the lengths match ?
                                @ (note that if a word is hidden,
                                @  the test will be always negative)
    bne 3f                          @ branch if they do not match
                                @ Now we compare strings characters
    mov r5, r0                      @ r5 contains searched string
    mov r6, r3                      @ r6 contains dict string
    add r6, r6, #5                  @ (we skip link and length fields)
                                @ r2 contains the length

2:
    ldrb r8, [r5], #1               @ compare character per character
    ldrb r9, [r6], #1
    cmp r8,r9
    bne 3f                          @ if they do not match, branch to 3
    subs r2,r2,#1                   @ decrement length
    bne 2b                          @ loop

                                @ here, strings are equal
    b 4f                            @ branch to 4

3:
    ldr r3, [r3]                    @ Mismatch, follow link to the next
    b 1b                            @ dictionary word
4:
    mov r0, r3                      @ move result to r0
    pop {r5,r6,r8,r9}      @ restore callee save registers
    push r0
    NEXT
/*
	(FIND) returns the dictionary pointer, but when compiling we need the codeword pointer (recall
	that FORTH definitions are compiled into lists of codeword pointers).  The standard FORTH
	word >CFA turns a dictionary pointer into a codeword pointer.

	The example below shows the result of:

		WORD DOUBLE (FIND) >CFA

	(FIND) returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	V					   V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	Notes:

	Because names vary in length, this isn't just a simple increment.

	In this FORTH you cannot easily turn a codeword pointer back into a dictionary entry pointer, but
	that is not true in most FORTH implementations where they store a back pointer in the definition
	(with an obvious memory/complexity cost).  The reason they do this is that it is useful to be
	able to go backwards (codeword -> dictionary entry) in order to decompile FORTH definitions
	quickly.

	What does CFA stand for?  My best guess is "Code Field Address".
*/

@ >CFA ( dictionary_address -- executable_address )
@ Transformat a dictionary address into a code field address

defcode ">CFA",4,,TCFA
    pop r0
    add r0,r0,#4            @ skip link field
    ldrb r1, [r0], #1       @ load and skip the length field
    and r1,r1,#F_LENMASK    @ keep only the length
    add r0,r0,r1            @ skip the name field
    add r0,r0,#3            @ find the next 4-byte boundary
    and r0,r0,#~3
    push r0
    NEXT

/*
	Related to >CFA is >DFA which takes a dictionary entry address as returned by (FIND) and
	returns a pointer to the first data field.

	(FIND) returns a pointer to this
	|				>CFA converts it to a pointer to this
	|					   |
	|					   |	>DFA converts it to a pointer to this
	|					   |		 |
	V					   V		 V
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 | DOCOL      | DUP        | +          | EXIT       |
	+---------+---+---+---+---+---+---+---+---+------------+------------+------------+------------+
						   codeword

	(Note to those following the source of FIG-FORTH / ciforth: My >DFA definition is
	different from theirs, because they have an extra indirection).

	You can see that >DFA is easily defined in FORTH just by adding 4 to the result of >CFA.
*/

        @@ >DFA ( dictionary_address -- data_field_address )
        @@ Return the address of the first data field

	defword ">DFA",4,,TDFA
	.int TCFA		// >CFA		(get code field address)
	.int INCR4		// 4+		(add 4 to it to get to next word)
	.int EXIT		// EXIT		(return from FORTH word)

@ CREATE ( address length -- ) Creates a new dictionary entry
@ in the data segment.
	defcode "HEADER,",7,,HEADER_COMMA

        pop r1          @ length of the word to insert into the dictionnary
        pop r0          @ address of the word to insert into the dictionnary

        ldr r2,=var_DP
        ldr r3,[r2]     @ load into r3 and r8 the location of the header
        mov r8,r3

        ldr r4,=var_LATEST
        ldr r5,[r4]     @ load into r5 the link pointer

        str r5,[r3]     @ store link here -> last

        add r3,r3,#4    @ skip link adress
        strb r1,[r3]    @ store the length of the word
        add r3,r3,#1    @ skip the length adress

        mov r7,#0       @ initialize the incrementation

1:
        cmp r7,r1       @ if the word is completley read
        beq 2f

        ldrb r6,[r0,r7] @ read and store a character
        strb r6,[r3,r7]

        add r7,r7,#1    @ ready to rad the next character

        b 1b

2:

        add r3,r3,r7            @ skip the word

        add r3,r3,#3            @ align to next 4 byte boundary
        and r3,r3,#~3

        str r8,[r4]             @ update LATEST and DP
        str r3,[r2]

        NEXT

/*
	Because I want to define : (COLON) in FORTH, not assembler, we need a few more FORTH words
	to use.

	The first is , (COMMA) which is a standard FORTH word which appends a 32 bit integer to the user
	memory pointed to by DP, and adds 4 to DP.  So the action of , (COMMA) is:

							previous value of DP
								 |
								 V
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
	| LINK    | 6 | D | O | U | B | L | E | 0 |             |  <data>    |
	+---------+---+---+---+---+---+---+---+---+-- - - - - --+------------+
                   len                         pad		              ^
									      |
									new value of DP

	and <data> is whatever 32 bit integer was at the top of the stack.

	, (COMMA) is quite a fundamental operation when compiling.  It is used to append codewords
	to the current word that is being compiled.
*/

        @ , ( n -- ) writes the top element from the stack at DP
	defcode ",",1,,COMMA
        pop     {SR0}
        ldr     SR1, =var_HERE
        ldr     SR2, [SR1]        @ read DP
        str     SR0, [SR2], #4    @ write value and increment address
        str     SR2, [SR1]        @ update DP

	NEXT

/*
	Our definitions of : (COLON) and ; (SEMICOLON) will need to switch to and from compile mode.

	Immediate mode vs. compile mode is stored in the global variable STATE, and by updating this
	variable we can switch between the two modes.

	For various reasons which may become apparent later, FORTH defines two standard words called
	[ and ] (LBRAC and RBRAC) which switch between modes:

	Word	Assembler	Action		Effect
	[	LBRAC		STATE := 0	Switch to immediate mode.
	]	RBRAC		STATE := 1	Switch to compile mode.

	[ (LBRAC) is an IMMEDIATE word.  The reason is as follows: If we are in compile mode and the
	interpreter saw [ then it would compile it rather than running it.  We would never be able to
	switch back to immediate mode!  So we flag the word as IMMEDIATE so that even in compile mode
	the word runs immediately, switching us back to immediate mode.
*/

	defcode "[",1,F_IMMED,LBRAC
	xor %eax,%eax
	movl %eax,var_STATE	// Set STATE to 0.
	NEXT

	defcode "]",1,,RBRAC
	movl $1,var_STATE	// Set STATE to 1.
	NEXT

/*
	Now we can define : (COLON) using HEADER, (HEADER_COMMA).  It just calls HEADER, (HEADER_COMMA),
	appends DOCOL (the codeword), sets the word HIDDEN and goes into compile mode.
*/

	defword ":",1,,COLON
	.int WORD		// Get the name of the new word
	.int HEADER_COMMA	// Create the dictionary entry / header
	.int LIT, DOCOL, COMMA	// Append DOCOL  (the codeword).
	.int LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition).
	.int RBRAC		// Go into compile mode.
	.int EXIT		// Return from the function.

/*
	; (SEMICOLON) is also elegantly simple.  Notice the F_IMMED flag.
*/

	defword ";",1,F_IMMED,SEMICOLON
	.int LIT, EXIT, COMMA	// Append EXIT (so the word will return).
	.int LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition).
	.int LBRAC		// Go back to IMMEDIATE mode.
	.int EXIT		// Return from the function.

/*
	EXTENDING THE COMPILER ----------------------------------------------------------------------

	Words flagged with IMMEDIATE (F_IMMED) aren't just for the FORTH compiler to use.  You can define
	your own IMMEDIATE words too, and this is a crucial aspect when extending basic FORTH, because
	it allows you in effect to extend the compiler itself.  Does gcc let you do that?

	Standard FORTH words like IF, WHILE, ." and so on are all written as extensions to the basic
	compiler, and are all IMMEDIATE words.

	The IMMEDIATE word toggles the F_IMMED (IMMEDIATE flag) on the most recently defined word,
	or on the current word if you call it in the middle of a definition.

	Typical usage is:

	: MYIMMEDWORD IMMEDIATE
		...definition...
	;

	but some FORTH programmers write this instead:

	: MYIMMEDWORD
		...definition...
	; IMMEDIATE

	The two usages are equivalent, to a first approximation.
*/

	defcode "IMMEDIATE",9,F_IMMED,IMMEDIATE
	movl var_LATEST,%edi	// LATEST word.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_IMMED,(%edi)	// Toggle the IMMED bit.
	NEXT

/*
	'addr HIDDEN' toggles the hidden flag (F_HIDDEN) of the word defined at addr.  To hide the
	most recently defined word (used above in : and ; definitions) you would do:

		LATEST @ HIDDEN

	'HIDE word' toggles the flag on a named 'word'.

	Setting this flag stops the word from being found by (FIND), and so can be used to make 'private'
	words.  For example, to break up a large word into smaller parts you might do:

		: SUB1 ... subword ... ;
		: SUB2 ... subword ... ;
		: SUB3 ... subword ... ;
		: MAIN ... defined in terms of SUB1, SUB2, SUB3 ... ;
		HIDE SUB1
		HIDE SUB2
		HIDE SUB3

	After this, only MAIN is 'exported' or seen by the rest of the program.
*/

	defcode "HIDDEN",6,,HIDDEN
	pop %edi		// Dictionary entry.
	addl $4,%edi		// Point to name/flags byte.
	xorb $F_HIDDEN,(%edi)	// Toggle the HIDDEN bit.
	NEXT

	defword "HIDE",4,,HIDE
	.int WORD		// Get the word (after HIDE).
	.int PAREN_FIND		// Look up in the dictionary.
	.int HIDDEN		// Set F_HIDDEN flag.
	.int EXIT		// Return.

/*
	['] (BRACKET_TICK) is a standard FORTH word which returns the codeword pointer of the next word.

	The common usage is:

	['] FOO ,

	which appends the codeword of FOO to the current word we are defining (this only works in compiled code).

	You tend to use ['] in IMMEDIATE words.  For example an alternate (and rather useless) way to define
	a literal 2 might be:

	: LIT2 IMMEDIATE
		['] LIT ,		\ Appends LIT to the currently-being-defined word
		2 ,		\ Appends the number 2 to the currently-being-defined word
	;

	So you could do:

	: DOUBLE LIT2 * ;

	(If you don't understand how LIT2 works, then you should review the material about compiling words
	and immediate mode).

	This definition of ['] uses a cheat which I copied from buzzard92.  As a result it only works in
	compiled code.  It is possible to write a version of ['] based on WORD, (FIND), >CFA which works in
	immediate mode too.

	This definition of ['] uses a cheat which I copied from buzzard92.  As a result it only works in
	compilied and when the word after it is not an immediate word. It is possible to write a version
	of ['] which works on immediate word, or to write another version based on WORD, (FIND), >CFA
	which works in immediate mode too.
*/
	defcode "[']",3,,BRACKET_TICK
	lodsl			// Get the address of the next word and skip it.
	pushl %eax		// Push it on the stack.
	NEXT

/*
	BRANCHING ----------------------------------------------------------------------

	It turns out that all you need in order to define looping constructs, IF-statements, etc.
	are two primitives.

	BRANCH is an unconditional branch. 0BRANCH is a conditional branch (it only branches if the
	top of stack is zero).

	The diagram below shows how BRANCH works in some imaginary compiled word.  When BRANCH executes,
	%esi starts by pointing to the offset field (compare to LIT above):

	+---------------------+-------+---- - - ---+------------+------------+---- - - - ----+------------+
	| (Dictionary header) | DOCOL |            | BRANCH     | offset     | (skipped)     | word       |
	+---------------------+-------+---- - - ---+------------+-----|------+---- - - - ----+------------+
								   ^  |			      ^
								   |  |			      |
								   |  +-----------------------+
								  %esi added to offset

	The offset is added to %esi to make the new %esi, and the result is that when NEXT runs, execution
	continues at the branch target.  Negative offsets work as expected.

	0BRANCH is the same except the branch happens conditionally.

	Now standard FORTH words such as IF, THEN, ELSE, WHILE, REPEAT, etc. can be implemented entirely
	in FORTH.  They are IMMEDIATE words which append various combinations of BRANCH or 0BRANCH
	into the word currently being compiled.

	As an example, code written like this:

		condition-code IF true-part THEN rest-code

	compiles to:

		condition-code 0BRANCH OFFSET true-part rest-code
					  |		^
					  |		|
					  +-------------+
*/

	defcode "BRANCH",6,,BRANCH
	add (%esi),%esi		// add the offset to the instruction pointer
	NEXT

	defcode "0BRANCH",7,,ZBRANCH
	pop %eax
	test %eax,%eax		// top of stack is zero?
	jz code_BRANCH		// if so, jump back to the branch function above
	lodsl			// otherwise we need to skip the offset
	NEXT

/*
	LITERAL STRINGS ----------------------------------------------------------------------

	LITSTRING is a primitive used to implement the ." and S" operators (which are written in
	FORTH).  See the definition of those operators later.

	TELL just prints a string.  It's more efficient to define this in assembly because we
	can make it a single Linux syscall.
*/

	defcode "LITSTRING",9,,LITSTRING
	lodsl			// get the length of the string
	push %esi		// push the address of the start of the string
	push %eax		// push it on the stack
	addl %eax,%esi		// skip past the string
 	addl $3,%esi		// but round up to next 4 byte boundary
	andl $~3,%esi
	NEXT

	defcode "TELL",4,,TELL
	mov $1,%ebx		// 1st param: stdout
	pop %edx		// 3rd param: length of string
	pop %ecx		// 2nd param: address of string
	mov $__NR_write,%eax	// write syscall
	int $0x80
	NEXT

/*
	COMBINING DATA AND BEHAVIOR --------------------------------------------------------

	A FORTH word with codeword DOCOL defines the word's behavior with other FORTH words.
	On the other hand, a built-in variable's behavior is simply push the pointer to its
	data onto the stack.

	One will wonder how can a FORTH word which owns complicated data specify its behavior on
	these data using other FORTH words. The magic word DODOES serves this purpose. 

	The diagram below shows how DODOES works.  When DODOES executes, it pushes the pointer to
	its data onto the stack and execute the behavior words pointed to by the behavior pointer.

	+---------------------+--------+---------+------+----------------+
	| (Dictionary header) | DODOES |         | data | behavior words |
	+---------------------+--------+---------+------+----------------+
			     behavior pointer |		  ^
					      |		  |
					      +-----------+

	When the behavior pointer is zero, there is no behavior words, DODOES simply pushes the pointer to
	its data onto the stack.

	+---------------------+--------+--------+------+
	| (Dictionary header) | DODOES |   0    | data |
	+---------------------+--------+--------+------+

*/

	.text
	.align	1
	.p2align 2,,3
DODOES: 
	cmpl $0,4(%eax)		// Is offset zero ?
	jz 1f
	lea -4(%ebp),%ebp
	mov %esi,(%ebp)
	mov 4(%eax),%esi	// Get pointer to behavior words
1:	lea 8(%eax),%eax
	push %eax		// Push the pointer to its data
	NEXT

	defconst "DODOES",6,,__DODOES,DODOES

/*
	QUIT AND INTERPRET ----------------------------------------------------------------------

	QUIT is the first FORTH function called, almost immediately after the FORTH system "boots".
	As explained before, QUIT doesn't "quit" anything.  It does some initialisation (in particular
	it clears the return stack) and it calls INTERPRET in a loop to interpret commands.  The
	reason it is called QUIT is because you can call it from your own FORTH words in order to
	"quit" your program and start again at the user prompt.

	INTERPRET is the FORTH interpreter ("toploop", "toplevel" or "REPL" might be a more accurate
	description -- see: http://en.wikipedia.org/wiki/REPL).
*/

	// QUIT must not return (ie. must not call EXIT).
	defword "QUIT",4,,QUIT
	.int RZ,RSPSTORE	// SR0 RSP!, clear the return stack
	.int INTERPRET		// interpret the next word
	.int BRANCH,-8		// and loop (indefinitely)

/*
	This interpreter is pretty simple, but remember that in FORTH you can always override
	it later with a more powerful one!
 */
	defcode "INTERPRET",9,,INTERPRET
	call _WORD		// Returns %ecx = length, %edi = pointer to word.

	// Is it in the dictionary?
	xor %eax,%eax
	movl %eax,interpret_is_lit // Not a literal number (not yet anyway ...)
	call _FIND		// Returns %eax = pointer to header or 0 if not found.
	test %eax,%eax		// Found?
	jz 1f

	// In the dictionary.  Is it an IMMEDIATE codeword?
	mov %eax,%edi		// %edi = dictionary entry
	movb 4(%edi),%al	// Get name+flags.
	push %ax		// Just save it for now.
	call _TCFA		// Convert dictionary entry (in %edi) to codeword pointer.
	pop %ax
	andb $F_IMMED,%al	// Is IMMED flag set?
	mov %edi,%eax
	jnz 4f			// If IMMED, jump straight to executing.

	jmp 2f

1:	// Not in the dictionary (not a word) so assume it's a literal number.
	incl interpret_is_lit
	call _NUMBER		// Returns the parsed number in %eax, %ecx > 0 if error
	test %ecx,%ecx
	jnz 6f
	mov %eax,%ebx
	mov $LIT,%eax		// The word is LIT

2:	// Are we compiling or executing?
	movl var_STATE,%edx
	test %edx,%edx
	jz 4f			// Jump if executing.

	// Compiling - just append the word to the current dictionary definition.
	call _COMMA
	mov interpret_is_lit,%ecx // Was it a literal?
	test %ecx,%ecx
	jz 3f
	mov %ebx,%eax		// Yes, so LIT is followed by a number.
	call _COMMA
3:	NEXT

4:	// Executing - run it!
	mov interpret_is_lit,%ecx // Literal?
	test %ecx,%ecx		// Literal?
	jnz 5f

	// Not a literal, execute it now.  This never returns, but the codeword will
	// eventually call NEXT which will reenter the loop in QUIT.
	jmp *(%eax)

5:	// Executing a literal, which means push it on the stack.
	push %ebx
	NEXT

6:	// Parse error (not a known word or a number in the current BASE).
	// Print an error message followed by up to 40 characters of context.
	mov $2,%ebx		// 1st param: stderr
	mov $errmsg,%ecx	// 2nd param: error message
	mov $errmsgend-errmsg,%edx // 3rd param: length of string
	mov $__NR_write,%eax	// write syscall
	int $0x80

	mov (currkey),%ecx	// the error occurred just before currkey position
	mov %ecx,%edx
	sub $buffer,%edx	// %edx = currkey - buffer (length in buffer before currkey)
	cmp $40,%edx		// if > 40, then print only 40 characters
	jle 7f
	mov $40,%edx
7:	sub %edx,%ecx		// %ecx = start of area to print, %edx = length
	mov $__NR_write,%eax	// write syscall
	int $0x80

	mov $errmsgnl,%ecx	// newline
	mov $1,%edx
	mov $__NR_write,%eax	// write syscall
	int $0x80

	NEXT

	.section .rodata
errmsg: .ascii "PARSE ERROR: "
errmsgend:
errmsgnl: .ascii "\n"

	.data			// NB: easier to fit in the .data section
	.align	1
	.p2align 2,,3
interpret_is_lit:
	.int 0			// Flag used to record if reading a literal

/*
	ANS Forth Core Words  ----------------------------------------------------------------------
	Some lower level ANS Forth CORE words are not presented in the orignal jonesforth. They are
	included here without explaination.
*/

/* Macros to deal with the return stack. */
	.macro PUSH2RSP reg1,reg2
	lea -8(%ebp),%ebp	// push reg1 and reg2 on to return stack
	movl \reg1,4(%ebp)
	movl \reg2,(%ebp)
	.endm

	.macro POP2RSP reg1, reg2
	mov (%ebp),\reg2	// pop top of return stack to reg1 and reg2
	mov 4(%ebp), \reg1
	lea 8(%ebp),%ebp
	.endm

	defcode "2*",2,,TWOMUL
	shll $1, (%esp)
	NEXT

	defcode "2/",2,,TWODIV
	sarl $1, (%esp)
	NEXT

	defcode "(DO)", 4,,PAREN_DO
	pop %eax		// pop parameter stack into %eax and %edx
	pop %edx
	PUSH2RSP %edx, %eax	// push it on to the return stack
	NEXT

	defcode "(LOOP)", 6,,PAREN_LOOP
	POP2RSP %edx, %eax
	inc %eax
	cmp %edx, %eax
	je 1f
	PUSH2RSP %edx, %eax
	add (%esi),%esi		// add the offset to the instruction pointer
	NEXT
1:
	lodsl
	NEXT

	defcode "(+LOOP)", 7,,PAREN_PLUS_LOOP
	POP2RSP %edx, %eax	// index in %eax, limit in %edx
	sub %edx, %eax		// index-limit in %eax
	pop %ebx		// n in %ebx
	add %eax, %ebx		// index-limit+n in %ebx
	xor %ebx, %eax		// (index-limit) and (index-limit+n) have different sign?
	js 1f
	add %edx, %ebx		// index+n in %ebx
	PUSH2RSP %edx, %ebx
	add (%esi),%esi		// add the offset to the instruction pointer
	NEXT
1:
	lodsl
	NEXT

	defcode "UNLOOP", 6,,UNLOOP
	lea 8(%ebp),%ebp
	NEXT

	defcode "I", 1,,I
	push (%ebp)
	NEXT

	defcode "J", 1,,J
	push 8(%ebp)
	NEXT

/*
	ODDS AND ENDS ----------------------------------------------------------------------

	CHAR puts the ASCII code of the first character of the following word on the stack.  For example
	CHAR A puts 65 on the stack.

	EXECUTE is used to run execution tokens.  See the discussion of execution tokens in the
	FORTH code for more details.

	SYSCALL0, SYSCALL1, SYSCALL2, SYSCALL3 make a standard Linux system call.  (See <asm/unistd.h>
	for a list of system call numbers).  As their name suggests these forms take between 0 and 3
	syscall parameters, plus the system call number.

	In this FORTH, SYSCALL0 must be the last word in the built-in (assembler) dictionary because we
	initialise the LATEST variable to point to it.  This means that if you want to extend the assembler
	part, you must put new words before SYSCALL0, or else change how LATEST is initialised.
*/

	defcode "CHAR",4,,CHAR
	call _WORD		// Returns %ecx = length, %edi = pointer to word.
	xor %eax,%eax
	movb (%edi),%al		// Get the first character of the word.
	push %eax		// Push it onto the stack.
	NEXT

	defcode "EXECUTE",7,,EXECUTE
	pop %eax		// Get xt into %eax
	jmp *(%eax)		// and jump to it.
				// After xt runs its NEXT will continue executing the current word.

	defcode "SYSCALL3",8,,SYSCALL3
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	pop %ecx		// Second parameter
	pop %edx		// Third parameter
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL2",8,,SYSCALL2
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	pop %ecx		// Second parameter
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL1",8,,SYSCALL1
	pop %eax		// System call number (see <asm/unistd.h>)
	pop %ebx		// First parameter.
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

	defcode "SYSCALL0",8,,SYSCALL0
	pop %eax		// System call number (see <asm/unistd.h>)
	int $0x80
	push %eax		// Result (negative for -errno)
	NEXT

/*
	DATA SEGMENT ----------------------------------------------------------------------

	Here we set up the Linux data segment, used for user definitions and variously known as just
	the 'data segment', 'user memory' or 'user definitions area'.  It is an area of memory which
	grows upwards and stores both newly-defined FORTH words and global variables of various
	sorts.

	It is completely analogous to the C heap, except there is no generalised 'malloc' and 'free'
	(but as with everything in FORTH, writing such functions would just be a Simple Matter
	Of Programming).  Instead in normal use the data segment just grows upwards as new FORTH
	words are defined/appended to it.

	There are various "features" of the GNU toolchain which make setting up the data segment
	more complicated than it really needs to be.  One is the GNU linker which inserts a random
	"build ID" segment.  Another is Address Space Randomization which means we can't tell
	where the kernel will choose to place the data segment (or the stack for that matter).

	Therefore writing this set_up_data_segment assembler routine is a little more complicated
	than it really needs to be.  We ask the Linux kernel where it thinks the data segment starts
	using the brk(2) system call, then ask it to reserve some initial space (also using brk(2)).

	You don't need to worry about this code.
*/
	.text
	.set INITIAL_DATA_SEGMENT_SIZE,65536
set_up_data_segment:
	xor %ebx,%ebx		// Call brk(0)
	movl $__NR_brk,%eax
	int $0x80
	movl %eax,var_DP	// Initialise DP to point at beginning of data segment.
	addl $INITIAL_DATA_SEGMENT_SIZE,%eax	// Reserve nn bytes of memory for initial data segment.
	movl %eax,%ebx		// Call brk(DP+INITIAL_DATA_SEGMENT_SIZE)
	movl $__NR_brk,%eax
	int $0x80
	ret

/*
	We allocate static buffers for the return static and input buffer (used when
	reading in files and text that the user types in).
*/
	.set RETURN_STACK_SIZE,8192
	.set BUFFER_SIZE,4096

	.bss
/* FORTH return stack. */
	.align	1
	.p2align 2,,3096
return_stack:
	.space RETURN_STACK_SIZE
return_stack_top:		// Initial top of return stack.

/* This is used as a temporary input buffer when reading from files or the terminal. */
	.align	1
	.p2align 2,,3096
buffer:
	.space BUFFER_SIZE

/*
	START OF FORTH CODE ----------------------------------------------------------------------

	We've now reached the stage where the FORTH system is running and self-hosting.  All further
	words can be written as FORTH itself, including words like IF, THEN, .", etc which in most
	languages would be considered rather fundamental.

	I used to append this here in the assembly file, but I got sick of fighting against gas's
	crack-smoking (lack of) multiline string syntax.  So now that is in a separate file called
	jonesforth.f

	If you don't already have that file, download it from http://annexia.org/forth in order
	to continue the tutorial.
*/

/* END OF jonesforth.S */
