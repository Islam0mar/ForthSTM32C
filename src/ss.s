		.title	"SFORTH"
@       ARM register usage
tos		.req	r5		@ top of data stack item
fpc     .req 	r6		@ FORTH vm instruction ptr
w		.req	r7		@ working register
rsp     .req 	r12		@ RETURN stack pointer
dsp     .req 	r13		@ DATA stack pointer
@		r13 stack pointer , r15 program counter 
@       r14, as usual, is used for the link address in subroutine calls
@       r0-r5 are used as scratch registers during calculation.
@       All other registers are free.

.macro __key
    ldr SR1, = USART1_SR
    ldr SR0, [SR1]
keyPoll:
    tst SR0, # USART_SR_RXNE        @ Check for reception 
    beq keyPoll                     @ wait for it
    ldr SR0, = USART1_DR
	.endm
@@@@@@@@@@@@@@@@
@ Assembly Constants
@@@@@@@@@@@@@@@@

.equ	TRUEE,		-1
.equ	FALSEE,		0

.equ	CHARR, 		1         	@byte size of a character
.equ	CELLL, 		4         	@byte size of a cell
.equ	MaxChar,	0x7F      	@Extended character set
					@  Use 07Fh for ASCII only
.equ	MaxString,	0xFF      	@max length of a string         
.equ	MaxSigned,	0x7FFFFFFF	@max value of signed integer
.equ	MaxUnsigned,	0xFFFFFFFF	@max value of unsigned integer
.equ	MaxNegative,	0x80000000	@max value of negative integer
					@  Used in doDO

.equ	PADSize,	134       	@PAD area size
.equ	RTCells,	64        	@return stack size
.equ	DTCells,	256       	@data stack size

.equ	BASEE,		10        	@default radix
.equ	OrderDepth, 	10        	@depth of search order stack
.equ   	MaxWLISTS,  	20        	@maximum number of wordlists
					@ 2 is used by the system
					@ 18 is available to Forth programs

.equ	NumTHROWMsgs,	58		@Number of throw messages

.equ   	COMPO,  	0x20      	@lexicon compile only bit
.equ   	IMMED,  	0x40           	@lexicon immediate bit
.equ   	MASKK,  	0x1F		@lexicon bit mask
					@extended character set
					@maximum name length = 1Fh

@NAC: added SPC, XON, XOFF
.equ	SPC,  		32 			@space (blank)
.equ	XON,  		17 			@CTRL-Q - flow control for FILE
.equ 	XOFF, 		19 			@CTRL-S
.equ  	BKSPP,		8  			@backspace
.equ 	TABB,		9  			@tab
.equ	LFF,  		10 			@line feed
.equ	CRR,  		13 			@carriage return
.equ	DEL,  		127			@delete

@For the ARM, this is the branch-with-link op-code@ the offset gets ORed in.
@Used by ?call and xt, but only xt, actually emits opcodes.
.equ	CALLL  		0xF000      @for ARM


@end of equates for host I/O

@ Initialize assembly variables

@The _NAME value is not used in the ARM port.. instead, makesrc.awk
@keeps track of an equivalent value, which is initialised by passing the
@parameter dict_pc into makesrc.awk with the value _NAME would have had.
@Everywhere that _NAME appears herein, special treatment is required.
@The other globals@ _THROW, _SLINK, _FLINK, _ENVLINK and _VAR are tracked
@correctly, so no special treatment is required for them.

	
.equ	MMU0,	0x08000000		@start of page tables
.equ	RAM0,	0x20000000		@bottom of RAM memory
.equ	RAMEnd,	0x20005000		@top of RAM memory
										@RAM size = 20KB
.equ	ROMEnd,	0x08020000		@end of ROM memory
	@ ROM size = 64k   = 0x08010000
	@ ROM size = 128KB = 0x08020000
	
.set			_THROW,	0                          @current throw string
.set			_SLINK, 0                          @force a null link
.set			_FLINK,	0                          @force a null link
.set			_ENVLINK,	0                      @force a null link
.set			_NAME,	ROMEnd                     @initialize name pointer
.set			_VAR,	RAM0                       @variable space pointer

@@@@@@@@@@@@@@@@
@ Assembly macros
@@@@@@@@@@@@@@@@
@@@ ARM Macros for push and pop -- we don't *always* use these
/* Macros to deal with the return stack. */
	.macro pushR reg
	str \reg, [rsp, #-4]!
	.endm

	.macro popR reg
	ldr \reg, [rsp], #4
	.endm

	.macro defword name, namelen, flags=0, label
	.section .rodata
	.align	2
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align	2		// padding to next 4 byte boundary
	.globl \label
\label :
	.int DoCOL		// codeword - the interpreter
	// list of word pointers follow
	.endm

	.macro defcode name, namelen, flags=0, label
	.section .rodata
	.align	2
	.globl name_\label
name_\label :
	.int link		// link
	.set link,name_\label
	.byte \flags+\namelen	// flags + length byte
	.ascii "\name"		// the name
	.align	2		// padding to next 4 byte boundary
	.globl \label
\label :
	.int code_\label	// codeword
	.text
	.align	1
	.p2align 2,,3
	.globl code_\label
code_\label :			// assembler code follows
	.endm

@       Add a THROW message in name space. THROW messages won't be
@       needed if target system do not need names of Forth words.

	.macro $THROWMSG string
	.acsii "\string"
	_THROW  = _THROW + CELLL
	.org	AddrTHROWMsgTbl - _THROW
	.word	_NAME
	.endm

	.macro $STR string
	.acsii "\string"
	.endm
	
@       Assemble inline direct threaded code ending.
	.macro NEXT
	ldr w, [fpc], #4
	bx  w
	.endm

@===============================================================

@@@@@@@@@@@@@@@@
@ Main entry points and COLD start data
@@@@@@@@@@@@@@@@
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
    ldr rsp, =return_stack_top      @ Set the initial return stack position
    bl  ClockInit
    bl	SystemCoreClockUpdate
    bl  set_up_data_segment         @ Set up the data segment
    bl  GPIO_Init
	cpsie i							@ Enable interrupt
    ldr fpc, =cold_start            @ Make the fpc point to cold_start
    NEXT                            @ Start the interpreter

	.section .rodata
cold_start:			// High-level code without a codeword.
	.int QUIT
		

@ COLD start moves the following to system variables.
@ MUST BE IN SAME ORDER AS SYSTEM VARIABLES.

		.align 2                          @align to cell boundary
UZERO:
		.word      	RXQ                     @'ekey?
		.word      	RXFetch                 @'ekey
		.word      	TXQ                     @'emit?
		.word      	TXStore                 @'emit
		.word      	Set_IO                  @'init-i/o
		.word      	DotOK                   @'prompt
		.word      	HI                      @'boot
		.word      	IOBYTES                 @control i/o
		.word      	0                       @SOURCE-ID
		.word      	AddrROMB                @CPVar
		.word      	AddrROMT                @NPVar
		.word      	AddrRAMB                @HereVar points RAM space.
		.word      	OptiCOMPILEComma        @'doWord nonimmediate word - compilation
		.word      	EXECUTE                 @nonimmediate word - interpretation
		.word      	DoubleAlsoComma         @not found word - compilateion
		.word      	DoubleAlso              @not found word - interpretation
		.word      	EXECUTE                 @immediate word - compilation
		.word      	EXECUTE                 @immediate word - interpretation
		.word      	10                      @BASE
		.word		CTOP                    @ROMB
		.word		NTOP                    @ROMT
		.word		VTOP                    @RAMB
		.word		RAMT0                   @RAMT
		.word		0                       @bal
		.word		0                       @notNONAME?
		.word		0                       @rakeVar
NOrder0:
		.word		2                       @#order
		.word		FORTH_WORDLISTAddr      @search order stack
		.word		NONSTANDARD_WORDLISTAddr
		.space  	(OrderDepth-2) * CELLL
		.word		FORTH_WORDLISTAddr      @current pointer
		.word		LASTFORTH               @FORTH-WORDLIST
		.word		NONSTANDARD_WORDLISTAddr        @wordlist link
		.word		FORTH_WORDLISTName      @name of the WORDLIST
		.word		LASTSYSTEM              @NONSTANDARD-WORDLIST
		.word		0                       @wordlist link
		.word		NONSTANDARD_WORDLISTName @name of the WORDLIST
		.space     	3*(MaxWLISTS-2) * CELLL @wordlist area
		.word		LASTENV                 @envQList
		.word		SysUserP                @user pointer
		.word		SysUserP                @system task's tid
		.space      CELLL                   @user1
		.word		SystemTaskName          @taskName
		.space      CELLL                   @throwFrame
		.space      CELLL                   @stackTop
		.word		Wake                    @status
		.word		SysStatus               @follower
		.word		SPP                     @system task's sp0
		.word		RPP                     @system task's rp0
ULAST:	

@ THROW code messages resides in top of name space. Messages must be
@ placed before any Forth words were defined.

@@@NAC assume that the macros put the table in the right place..
@@@NAC the idea of the THROWTABLE macro is that it updates _NAME to
@@@NAC account for the space needed for the messages' jump table.
@@@NAC thereafter, the messages can be emitted at _NAME
@@@ORG  _NAME
@@@AddrTHROWMsgTbl:
@@@
@@@_NAME   SETA _NAME - NumTHROWMsgs*CELLL

	$THROWTABLE AddrTHROWMsgTbl,NumTHROWMsgs

	$STR        CPUStr,'ARM_CortexM3'
	$STR        ModelStr,'STM32F103C8T6'
	$STR        VersionStr,'1.0.0'
								    @THROW code
	$THROWMSG       'ABORT'                                         @-01
	$THROWMSG       'ABORT\"'                                        @-02
	$THROWMSG       'stack overflow'                                @-03
	$THROWMSG       'stack underflow'                               @-04
	$THROWMSG       'return stack overflow'                         @-05
	$THROWMSG       'return stack underflow'                        @-06
	$THROWMSG       'do-loops nested too deeply during execution'   @-07
	$THROWMSG       'dictionary overflow'                           @-08
	$THROWMSG       'invalid memory address'                        @-09
	$THROWMSG       'division by zero'                              @-10
	$THROWMSG       'result out of range'                           @-11
	$THROWMSG       'argument type mismatch'                        @-12
	$THROWMSG       'undefined word'                                @-13
	$THROWMSG       'interpreting a compile-only word'              @-14
	$THROWMSG       'invalid FORGET'                                @-15
	$THROWMSG       'attempt to use zero-length string as a name'   @-16
	$THROWMSG       'pictured numeric output string overflow'       @-17
	$THROWMSG       'parsed string overflow'                        @-18
	$THROWMSG       'definition name too long'                      @-19
	$THROWMSG       'write to a read-only location'                 @-20
	$THROWMSG       'unsupported operation (e.g., AT-XY on a too-dumb terminal)' @-21
	$THROWMSG       'control structure mismatch'                    @-22
	$THROWMSG       'address alignment exception'                   @-23
	$THROWMSG       'invalid numeric argument'                      @-24
	$THROWMSG       'return stack imbalance'                        @-25
	$THROWMSG       'loop parameters unavailable'                   @-26
	$THROWMSG       'invalid recursion'                             @-27
	$THROWMSG       'user interrupt'                                @-28
	$THROWMSG       'compiler nesting'                              @-29
	$THROWMSG       'obsolescent feature'                           @-30
	$THROWMSG       '>BODY used on non-CREATEd definition'          @-31
	$THROWMSG       'invalid name argument (e.g., TO xxx)'          @-32
	$THROWMSG       'block read exception'                          @-33
	$THROWMSG       'block write exception'                         @-34
	$THROWMSG       'invalid block number'                          @-35
	$THROWMSG       'invalid file position'                         @-36
	$THROWMSG       'file I/O exception'                            @-37
	$THROWMSG       'non-existent file'                             @-38
	$THROWMSG       'unexpected end of file'                        @-39
	$THROWMSG       'invalid BASE for floating point conversion'    @-40
	$THROWMSG       'loss of precision'                             @-41
	$THROWMSG       'floating-point divide by zero'                 @-42
	$THROWMSG       'floating-point result out of range'            @-43
	$THROWMSG       'floating-point stack overflow'                 @-44
	$THROWMSG       'floating-point stack underflow'                @-45
	$THROWMSG       'floating-point invalid argument'               @-46
	$THROWMSG       'compilation word list deleted'                 @-47
	$THROWMSG       'invalid POSTPONE'                              @-48
	$THROWMSG       'search-order overflow'                         @-49
	$THROWMSG       'search-order underflow'                        @-50
	$THROWMSG       'compilation word list changed'                 @-51
	$THROWMSG       'control-flow stack overflow'                   @-52
	$THROWMSG       'exception stack overflow'                      @-53
	$THROWMSG       'floating-point underflow'                      @-54
	$THROWMSG       'floating-point unidentified fault'             @-55
	$THROWMSG       'QUIT'                                          @-56
	$THROWMSG       'exception in sending or receiving a character' @-57
	$THROWMSG       '[IF], [ELSE], or [THEN] exception'             @-58

@@@NAC at this point need to ALIGN the value of _NAME, since we packed
@@@the strings of the throw table but  $CODE assumes that NAME is aligned.
	$ALIGN_NAME


@@@@@@@@@@@@@@@@
@ System dependent words -- Must be re-defined for each system.
@@@@@@@@@@@@@@@@

@   !IO         ( -- )  "store i o"
@               Initialize the serial devices for terminal I/O

		$CODE   3,'!IO',STOIO,_SLINK
@MJG FIXME: I've got to write this!
		$NEXT


@   TRUE        ( -- f )
@               Return the TRUE flag

		$CONST  4,'TRUE',FTRUE,TRUEE,_SLINK

@   RX?         ( -- flag )
@               Return true if key is pressed.

		$CODE   3,'RX?',RXQ,_SLINK
		pushD   tos                     @make room for flag
		ldr     r0,=AddrIOBYTES
		ldr     r1,[r0]
		ands	r1,r1,#&ff
		cmp	r1,#1
		ldreq	r4,=COM1Port
		ldrne	r4,=COM2Port
		LDRB    tos, [r4,#LineStatus]   @look for a character, note that reading this
		TST     tos, #LineDRMsk         @register also clears any errors
		mov     tos, #0                 @predict no char available
		subne   tos, tos, #1            @change flag to -1 (TRUE)
		$NEXT

@   RX@         ( -- u )
@               Receive one keyboard event u.

		$CODE   3,'RX@',RXFetch,_SLINK
		pushD   tos                     @make room
		ldr     r0,=AddrIOBYTES
		ldr     r1,[r0]
		ands	r1,r1,#&ff
		cmp	r1,#1
		ldreq	r4,=COM1Port
		ldrne	r4,=COM2Port
		LDRB    tos, [r4,#Rx]           @Read the character
		$NEXT


@   TX?         ( -- flag )
@               Return true if output device is ready or device state is
@               indeterminate.

		$CODE  3,'TX?',TXQ,_SLINK
		pushD   tos                     @ make room
		ldr     r0,=AddrIOBYTES
		ldr     r1,[r0]
		ands	r1,r1,#&ff
		cmp	r1,#1
		ldreq	r4,=COM1Port
		ldrne	r4,=COM2Port
		LDRB    r2,[r4,#LineStatus]
		TST     r2,#LineTHREMsk         @Wait until ready to queue character
		ldr     tos,=TRUEE              @predict ready
		ldrne   tos,=FALSEE
		$NEXT


@   TX!         ( u -- )
@               Send char to the output device. Have to wait until the output
@               device is ready because TX? is NOT called first

		$CODE   3,'TX!',TXStore,_SLINK
		ldr     r0,=AddrIOBYTES
		ldr     r1,[r0]
		ands	r1,r1,#&ff
		cmp	r1,#1
		ldreq	r4,=COM1Port
		ldrne	r4,=COM2Port
txstoreloop     LDRB    r2,[r4,#LineStatus]
		TST     r2,#LineTHREMsk         @Wait until ready to queue character
		beq     txstoreloop
		strb    tos,[r4,#Tx]            @Queue the character
		popD    tos
		$NEXT


@   CR          ( -- )                          \ CORE
@               Carriage return and linefeed.
@
@   : CR        carriage-return-char EMIT  linefeed-char EMIT @

		$COLON  2,'CR',CR,_FLINK
		DW      DoLIT,CRR,EMIT,DoLIT,LFF,EMIT,EXIT

@   BYE         ( -- )                          \ TOOLS EXT
@               Return control to the host operation system, if any.

		$CODE   3,'BYE',BYE,_FLINK
		bl      DoLIST                  @fake a colon definition
		$INSTR  ' Sorry - nowhere to go!'
		DW      TYPEE,CR,EXIT

@MJG FIXME: we'll have to return to EPOC's cleanup code

@   hi          ( -- )
@
@   : hi        CR ." hForth "
@               S" CPU" ENVIRONMENT? DROP TYPE SPACE
@               S" model" ENVIRONMENT? DROP TYPE SPACE [CHAR] v EMIT
@               S" version"  ENVIRONMENT? DROP TYPE
@               ."  by Wonyong Koh, 1997" CR
@               ." EPOC port by matt@gumbley.demon.co.uk" CR @
@               ." ALL noncommercial and commercial uses are granted." CR
@               ." Please send comment, bug report and suggestions to:" CR
@               ." matt@gumbley.demon.co.uk" CR

		$COLON  2,'hi',HI,_SLINK
		DW      CR
		$INSTR  'hForth '
		DW      TYPEE
		$INSTR  'CPU'
		DW      ENVIRONMENTQuery,DROP,TYPEE,SPACE
		$INSTR  'model'
		DW      ENVIRONMENTQuery,DROP,TYPEE,SPACE,DoLIT,'v',EMIT
		$INSTR  'version'
		DW      ENVIRONMENTQuery,DROP,TYPEE
		$INSTR  ' by Wonyong Koh, 1997'
		DW      TYPEE,CR
		$INSTR  'EPOC port by matt@gumbley.demon.co.uk'
		DW      TYPEE,CR
		$INSTR  'All noncommercial and commercial uses are granted.'
		DW      TYPEE,CR
		$INSTR  'Please send comment, bug report and suggestions to:'
		DW      TYPEE,CR
		$INSTR  'matt@gumbley.demon.co.uk'
		DW      TYPEE,CR,EXIT

@   COLD        ( -- )
@               The cold start sequence execution word.
@
@   : COLD      sysVar0 var0 [ sysVar0End sysVar0 - ] LITERAL
@               MOVE                            \ initialize system variable
@               xhere DUP @                     \ free-ROM [free-ROM]
@               INVERT SWAP 2DUP ! @ XOR        \ writable ROM?
@               IF RAMB TO cpVar RAMT TO npVar THEN
@               sp0 sp! rp0 rp!                 \ initialize stack
@               'init-i/o EXECUTE
@               'boot EXECUTE
@               QUIT @                          \ start interpretation

		$COLON  4,'COLD',COLD,_SLINK
		DW      SysVar0,VarZero,DoLIT,ULAST-UZERO,MOVE
		DW      XHere,DUPP,Fetch,INVERT,SWAP,TwoDUP,Store,Fetch,XORR
		DW      ZBranch,COLD1
		DW      RAMB,DoTO,AddrCPVar,RAMT,DoTO,AddrNPVar
COLD1           DW      SPZero,SPStore,RPZero,RPStore
		DW      TickINIT_IO,EXECUTE,TickBoot,EXECUTE
		DW      QUIT

@   set-i/o ( -- )
@               Set input/output device. (Includes initialising any hardware)
@
@   : set-i/o   set-i/ov !IO @

		$COLON  7,'set-i/o',Set_IO,_SLINK
		DW      Set_IOV,STOIO,EXIT

@   set-i/ov ( -- )
@               Set default input/output vectors.
@
@   : set-i/ov  sysVar0 var0 4 CELLS MOVE @      \ set i/o vectors

		$COLON  8,'set-i/ov',Set_IOV,_SLINK
		DW      SysVar0,VarZero,DoLIT,4*CELLL,MOVE
	        DW      EXIT

@   FILE        ( -- )
@               Set FILE bit in IOBYTES to disable local echo and impose
@               XON/XOFF flow control for host file download
@   : FILE      IOBYTES 10000000 OR TO IOBYTES @

		$COLON 4,'FILE',FILE,_SLINK
		DW      DoLIT,AddrIOBYTES,Fetch,DoLIT,010000000h,ORR
		DW      DoTO,AddrIOBYTES,EXIT

@   HAND        ( -- )
@               Clear FILE bit in IOBYTES to turn off XON/XOFF handshake
@               and turn on local echo
@   : HAND      IOBYTES EFFFFFFF AND TO IOBYTES @

		$COLON 4,'HAND',HAND,_SLINK
		DW      DoLIT,AddrIOBYTES
		DW      Fetch,DoLIT,0efffffffh,ANDD,DoTO,AddrIOBYTES,EXIT

@   FLOW-ON     ( -- )
@               Send an XON character for the file downloading process.
@   : FLOW-ON   XON# EMIT @

		$COLON  7,'FLOW-ON',FLOW_ON,_SLINK
		DW      DoLIT,XON,EMIT,EXIT

@   FLOW-OFF    ( -- )
@               Send an XOFF character for the file downloading process@ ONLY
@               if FILE bit is set
@   : FLOW-OFF  IOBYTES 10000000 AND IF XOFF EMIT THEN @

		$COLON  8,'FLOW-OFF',FLOW_OFF,_SLINK
		DW      DoLIT,AddrIOBYTES,Fetch,DoLIT,010000000h,ANDD
		DW      ZBranch,FLOF1
		DW      DoLIT,XOFF,EMIT
FLOF1           DW      EXIT



@@@@@@@@@@@@@@@@
@ Non-Standard words - Processor-dependent definitions
@       32-bit Forth for ARM RISC
@@@@@@@@@@@@@@@@

@ microdebugger for debugging new hForth ports by NAC.
@
@ The major problem with debugging Forth code at the assembler level is that
@ most of the definitions are lists of execution tokens that get interpreted
@ (using doLIST) rather than executed directly. As far as the native processor
@ is concerned, these xt are data, and a debugger cannot be set to trap on
@ them.
@
@ The solution to that problem would seem to be to trap on the native-machine
@ 'call' instruction at the start of each definition. However, the threaded
@ nature of the code makes it very difficult to follow a particular definition
@ through: many definitions are used repeatedly through the code. Simply
@ trapping on the 'call' leads to multiple unwanted traps.
@
@ Consider, for example, the code for doS" --
@
@          DW      RFrom,SWAP,TwoDUP,Plus,ALIGNED,ToR,EXIT
@
@ It would be useful to run each word in turn@ at the end of each word the
@ effect upon the stacks could be checked until the faulty word is found.
@
@ This technique allows you to do exactly that.
@
@ All definitions end with $NEXT -- either directly (code definitions) or
@ indirectly (colon definitions terminating in EXIT, which is itself a code
@ definition). The action of $NEXT is to use the fpc for the next word to
@ fetch the xt and jumps to it.
@
@ To use the udebug routine, replace the $NEXT expansion with a jump (not a
@ call) to the routine udebug (this requires you to reassemble the code)
@
@ When you want to debug a word, trap at the CALL doLIST at the start of the
@ word and then load the location trapfpc with the address of the first xt
@ of the word. Make your debugger trap when you execute the final instruction
@ in the udebug routine. Now execute your code and your debugger will trap
@ after the completion of the first xt in the definition. To stop debugging,
@ simply set trapfpc to 0.
@
@ This technique has a number of limitations:
@ - It is an assumption that an xt of 0 is illegal
@ - You cannot automatically debug a code stream that includes inline string
@   definitions, or any other kind of inline literal. You must step into the
@   word that includes the definition then hand-edit the appropriate new value
@   into trapfpc
@ Clearly, you could overcome these limitations by making udebug more
@ complex -- but then you run the risk of introducing bugs in that code.

udebug          ldr r0,=RAM0            @ where UZERO table will go to
		ldr r1,[r0]
		cmps r1,fpc             @ compare the stored address with
					@ the address we're about to get the
					@ next xt from
		ldrne pc, [fpc], #CELLL @ not the trap address, so we're done
		add r1,fpc,#CELLL       @ next time trap on the next xt
		str r1, [r0]
		ldr pc, [fpc], #CELLL   @ make debugger TRAP at this address


@===============================================================
@@ StrongARM-specific words for getting at the internals of
@@ the chip
@MJG FIXME: may have to remove these as they may not be available on the ARM710.

conm            .equ &1000
coffm           .equ &ffffefff

@   MMUPTAB     ( -- a-addr )
@               Return the start address of the MMU page table
		$CONST  7,"MMUPTAB",MMUPTAB,MMU0,_SLINK

@   CHIPID      ( -- n )
@               Read chip ID

		$CODE   6,'CHIPID',CHIPID,_SLINK
		pushD   tos
		mrc     p15,0,tos,c0,c1,0
		$NEXT

@   ION         ( -- )
@               Turn on Icache

		$CODE   3,'ION',ION,_SLINK
		ldr     r1,=conm                @mask Icache ON
		mrc     p15,0,r2,c1,c1,0
		orr     r2,r2,r1                @Icache ON
		mcr     p15,0,r2,c1,c1,0
		$NEXT

@   IOFF        ( -- )
@               Turn off Icache

		$CODE   4,'IOFF',IOFF,_SLINK
		ldr     r1,=coffm               @mask Icache OFF
		mrc     p15,0,r2,c1,c1,0
		and     r2,r2,r1                @Icache OFF
		mcr     p15,0,r2,c1,c1,0
		$NEXT

@   IFLUSH      ( -- )
@               Flush the Icache

		$CODE   6,'IFLUSH',IFLUSH,_SLINK
		mcr     p15,0,r2,c7,c5,0
		$NEXT

@   DFLUSH      ( -- )
@               Flush the Dcache by forcing data out to memory
@               This algorithm comes from the SA-110 spec. Could optimise
@               it to half the loopcount by selecting an unused
@               address range and adding an MCR.

		$CODE   6,'DFLUSH',DFLUSH,_SLINK
		mov     r0, #0
		add     r1, r0, #32768
01              ldr     r2, [r0], #32
		teq     r1, r0
		bne     %B01
		$NEXT

@   TLBFLUSH    ( -- )
@               Flush the I and D TLBs

		$CODE   8,'TLBFLUSH',TLBFLUSH,_SLINK
		mcr     p15,0,r2,c8,c6,0
		$NEXT

@   MMUON       ( -- )
@               Turn on the MMU, WB, Icache, Dcache

		$CODE   5,'MMUON',MMUON,_SLINK
		ldr     r1, =&100d
		mrc     p15,0,r2,c1,c1,0
		orr     r2,r2,r1
		mcr     p15,0,r2,c1,c1,0
		$NEXT

@   MMUOFF      ( -- )
@               Turn off the MMU, WB, Icache, Dcache

		$CODE   6,'MMUOFF',MMUOFF,_SLINK
		ldr     r1, =&eff2
		mrc     p15,0,r2,c1,c1,0
		and     r2,r2,r1
		mcr     p15,0,r2,c1,c1,0
		$NEXT

@   WBDRAIN     ( -- )
@               Drain the write buffer

		$CODE   7,'WBDRAIN',WBDRAIN,_SLINK
		mcr     p15,0,r2,c7,c10,4
		$NEXT

@   CKSWON      ( -- )
@               clock switching ON

		$CODE   6,'CKSWON',CKSWON,_SLINK
		mcr     p15,0,r2,c15,c1,2
		$NEXT

@   CKSWOFF     ( -- )
@               clock switching OFF

		$CODE   7,'CKSWOFF',CKSWOFF,_SLINK
		mcr     p15,0,r2,c15,c2,2
		$NEXT

@   WAI         ( -- )
@               Wait for interrupt

		$CODE   3,'WAI',WAI,_SLINK
		mcr     p15,0,r2,c15,c8,2
		$NEXT

@   TTB!        ( n -- )
@               Store n as the translation table base address

		$CODE   4,'TTB!',TTBWR,_SLINK
		mcr     p15,0,tos,c2,c1,0
		popD    tos
		$NEXT

@   DAC@        ( -- n )
@               Read the domain access control register

		$CODE   4,'DAC@',DACat,_SLINK
		pushD   tos
		mrc     p15,0,tos,c3,c1,0
		$NEXT

@   DAC!        ( n -- )
@               Store n in the domain access control register

		$CODE   4,'DAC!',DACstore,_SLINK
		mcr     p15,0,tos,c3,c1,0
		popD    tos
		$NEXT

@   IDflushline  ( a-addr -- )
@               Ensure cache coherency after generating a new op-code
@               at a-addr. For machines with unified caches this is a DROP but
@               for machines with separate I and D caches you must flush the
@               Dcache (in case the code word is sitting in a dirty block there)
@               and then flush the Icache (in case it has a copy of the old
@               value at that location).
@               Currently, the only word that uses this is xt,

		$CODE 11,'IDflushline',IDflushline,_SLINK
@                       p15,??, arm_reg, co-proc_register, CRm, OPC_2
		mcr     p15,0,tos,c7,c10,1      @clean Dcache entry 
		mcr     p15,0,tos,c7,c6,1       @flush Dcache entry 
		mcr     p15,0,tos,c7,c10,4      @drain write buffer
		mcr     p15,0,tos,c7,c5,0       @flush Icache
		popD    tos
		$NEXT

@   same?       ( c-addr1 c-addr2 u -- -1|0|1 )
@               Return 0 if two strings, ca1 u and ca2 u, are same@ -1 if
@               string, ca1 u is smaller than ca2 u@ 1 otherwise. Used by
@               '(search-wordlist)'. Code definition is preferred to speed up
@               interpretation. Colon definition is shown below.
@
@   : same?     ?DUP IF         \ null strings are always same
@                  0 DO OVER C@ OVER C@ XOR \ 0 (false) if match.. so continue
@                       IF UNLOOP C@ SWAP C@ > 2* 1+ EXIT THEN
@                       CHAR+ SWAP CHAR+ SWAP
@                  LOOP
@               THEN 2DROP 0 @
@
@                 $COLON  5,'same?',SameQ,_SLINK
@                 DW      QuestionDUP,ZBranch,SAMEQ4
@                 DW      Zero,DoDO
@ SAMEQ3          DW      OVER,CFetch,OVER,CFetch,XORR,ZBranch,SAMEQ2
@                 DW      UNLOOP,CFetch,SWAP,CFetch,GreaterThan
@                 DW      TwoStar,OnePlus,EXIT
@ SAMEQ2          DW      CHARPlus,SWAP,CHARPlus
@                 DW      DoLOOP,SAMEQ3
@ SAMEQ4          DW      TwoDROP,Zero,EXIT

		$CODE   5,'same?',SameQ,_SLINK
		popD    r0              @c-addr2
		popD    r1              @c-addr1
		orrs    tos, tos, tos
		beq     SAME1   @null string always matches@ exit with tos=0
SAME2           ldrb    r2, [r0], #1    @char at c-addr2
		ldrb    r3, [r1], #1    @char at c-addr1
		cmp     r2, r3          @flags for c2>c1
		bne     SAME1           @mismatch
		subs    tos, tos, #1
		bne     SAME2           @match so far, more string to do
		@match, tos=0
		$NEXT                   @could simply fall through the movCOND
SAME1
		movgt   tos, #1
		movlt   tos, #-1
		$NEXT

@   (search-wordlist)   ( c-addr u wid -- 0 | xt f 1 | xt f -1)
@               Search word list for a match with the given name.
@               Return execution token and not-compile-only flag and
@               -1 or 1 ( IMMEDIATE) if found. Return 0 if not found.
@
@               format is: wid---->[   a    ]
@                                      |
@                                      V
@               [   xt'  ][   a'   ][ccbbaann][ggffeedd]...
@                             |
@                             +--------+
@                                      V
@               [   xt'' ][   a''  ][ccbbaann][ggffeedd]...
@
@               a, a' etc. point to the cell that contains the name of the
@               word. The length is in the low byte of the cell (little byte
@               for little-endian, big byte for big-endian).
@               Eventually, a''' contains 0 to indicate the end of the wordlist
@               (oldest entry). a=0 indicates an empty wordlist.
@               xt is the xt of the word. aabbccddeedd etc. is the name of
@               the word, packed into cells.
@
@   : (search-wordlist)
@               ROT >R SWAP DUP 0= IF -16 THROW THEN
@                               \ attempt to use zero-length string as a name
@               >R              \ wid  R: ca1 u
@               BEGIN @         \ ca2  R: ca1 u
@                  DUP 0= IF R> R> 2DROP EXIT THEN      \ not found
@                  DUP COUNT [ =MASK ] LITERAL AND R@ = \ ca2 ca2+char f
@                     IF   R> R@ SWAP DUP >R            \ ca2 ca2+char ca1 u
@                          same?                        \ ca2 flag
@                   \ ELSE DROP -1      \ unnecessary since ca2+char is not 0.
@                     THEN
@               WHILE cell-             \ pointer to next word in wordlist
@               REPEAT
@               R> R> 2DROP DUP name>xt SWAP            \ xt ca2
@               C@ DUP [ =COMP ] LITERAL AND 0= SWAP
@               [ =IMED ] LITERAL AND 0= 2* 1+ @
@
@                 $COLON  17,'(search-wordlist)',ParenSearch_Wordlist,_SLINK
@                 DW      ROT,ToR,SWAP,DUPP,ZBranch,PSRCH6
@                 DW      ToR
@ PSRCH1          DW      Fetch
@                 DW      DUPP,ZBranch,PSRCH9
@                 DW      DUPP,COUNT,DoLIT,MASKK,ANDD,RFetch,Equals
@                 DW      ZBranch,PSRCH5
@                 DW      RFrom,RFetch,SWAP,DUPP,ToR,SameQ
@ PSRCH5          DW      ZBranch,PSRCH3
@                 DW      CellMinus,Branch,PSRCH1
@ PSRCH3          DW      RFrom,RFrom,TwoDROP,DUPP,NameToXT,SWAP
@                 DW      CFetch,DUPP,DoLIT,COMPO,ANDD,ZeroEquals,SWAP
@                 DW      DoLIT,IMMED,ANDD,ZeroEquals,TwoStar,OnePlus,EXIT
@ PSRCH9          DW      RFrom,RFrom,TwoDROP,EXIT
@ PSRCH6          DW      DoLIT,-16,THROW

		$CODE   17,'(search-wordlist)',ParenSearch_Wordlist,_SLINK
		popD    r0              @u
		popD    r1              @c-addr
		orrs    r0, r0, r0
		moveq   tos,#-16
		beq     THROW   @attempt to use 0-length string as a name
		add     r6, r1, r0      @point past reference string
PSRCH2          ldr     tos,[tos]       @link to next word
		orrs    tos, tos, tos
		beq     PSRCH3  @link of 0 indicates end of word list
		@ get length byte and point to next-word link
		ldrb    r5, [tos], #-CELLL
		and     r2, r5, #MASKK  @get length
		cmp     r2, r0          @same length as word we're looking for?
		bne     PSRCH2          @no. Try next word in the list
		add     r2, tos, #5     @point to 1st byte of string in dict'y
		mov     r7, r1          @take a copy of the start address
		@now compare strings at r7, r2 until r7=r6
PSRCH4          ldrb    r3, [r7], #1
		ldrb    r4, [r2], #1
		subs    r3, r4, r3
		bne     PSRCH2  @mismatch. Try next word in the list
		subs    r4, r7, r6
		bne     PSRCH4          @match so far, keep going
@match!! and we tricked 0 into r3 and r4 for later use..
		ldr     r0, [tos, #-CELLL]
		pushD   r0              @stack the xt
		tst     r5, #COMPO
		@ eq => !COMPO, want to push -1. ne => COMPO push 0
		subeq   r3, r3, #1      @r3 started as 0
		pushD   r3
		ands    tos, r5, #IMMED
		@ eq => tos=0 => IMMED clear
		movne   tos, #2
		sub     tos, tos, #1    @1=>SET, -1=>CLEAR
PSRCH3
		$NEXT

@   ?call       ( xt1 -- xt1 0 | a-addr xt2 )
@               If xt1 starts with a machine CALL instruction then leave
@               xt of the CALLed routine and the address of the cell following
@               the machine call at xt1. Otherwise leave xt1 and 0. See
@               optiCOMPILE for an example of usage
@
@ 8086 version:
@   : ?call     DUP @ call-code =
@               IF   CELL+ DUP @ SWAP CELL+ DUP ROT + EXIT THEN
@                       \ Direct Threaded Code 8086 relative call
@               0 @
@
@ ARM version: call is one cell and contains a signed 24-bit relative
@ offset. The offset must be fixed up for pipeline prefetch:
@   : ?call     DUP @ 0ff000000h AND call-code =
@               \ that call-detection is crude - not an exact check..
@               IF DUP DUP @ 00ffffffh AND    \ it's a branch.. get offset
@               DUP 007fffffh > IF
@                             00ff000000h OR \ sign extend the offset
@                           THEN
@               2 LSHIFT                      \ convert to byte offset
@               + CELL+ CELL+                 \ fix up for pipeline prefetch
@               SWAP CELL+ SWAP EXIT THEN
@               0 @

		$COLON  5,'?call',QCall,_SLINK
		DW      DUPP,Fetch,DoLIT,0ff000000h,ANDD,DoLIT,CALLL,Equals
		DW      ZBranch,QCALL1
		DW      DUPP,DUPP,Fetch,DoLIT,0ffffffh,ANDD,DUPP
		DW      DoLIT,07fffffh,GreaterThan,ZBranch,QCALL2
		DW      DoLIT,0ff000000h,ORR
QCALL2          DW      DoLIT,2,LSHIFT,Plus,CELLPlus,CELLPlus
		DW      SWAP,CELLPlus,SWAP,EXIT
QCALL1          DW      Zero,EXIT

@   xt,         ( xt1 -- xt2 )
@               Take a run-time word xt1 for :NONAME , CONSTANT , VARIABLE and
@               CREATE . Return xt2 of current definition.
@
@ 8086 version:
@   : xt,       xhere ALIGNED DUP TOxhere SWAP
@               call-code code,         \ Direct Threaded Code
@               xhere CELL+ - code, @   \ 8086 relative call
@
@ ARM version: call is one cell and contains a signed 24-bit relative
@ offset. The offset must be fixed up for pipeline prefetch:
@   : xt,       xhere ALIGNED DUP TOxhere SWAP
@               xhere - CELL- CELL- 2 RSHIFT    \ get signed offset
@               00ffffffh AND                   \ mask off high-order sign bits
@               call_code OR                    \ make the opcode 
@               xhere swap                      \ remember where it will go
@               code, IDflushline @             \ emit it and purge the block

		$COLON  3,'xt,',xtComma,_SLINK
		DW      XHere,ALIGNED,DUPP,TOXHere,SWAP
		DW      XHere,Minus,CellMinus,CellMinus,DoLIT,2,RSHIFT
		DW      DoLIT,0FFFFFFH,ANDD
		DW      DoLIT,CALLL,ORR,XHere,SWAP
		DW      CodeComma,IDflushline,EXIT

@   doLIT       ( -- x )
@               Push an inline literal. The inline literal is at the current
@               value of the fpc, so put it onto the stack and point past it.

		$CODE   COMPO+5,'doLIT',DoLIT,_SLINK
		pushD   tos
		ldr     tos, [fpc], #CELLL      @get literal and inc to next forth word
		$NEXT

@   doCONST     ( -- x )
@               Run-time routine of CONSTANT and VARIABLE. When you quote a
@               constant or variable you execute its code, which consists of a
@               call to here, followed by an inline literal. The literal is a
@               constant (for a CONSTANT) or the address at which a VARIABLE's
@               value is stored. Although you come here as the result of a
@               native machine call, you never go back to the return address
@               -- you jump back up a level by continuing at the new fpc value.
@               For 8086, Z80 the inline literal is at the return address
@               stored on the top of the hardware stack. For the ARM, we came
@               here through a bl (branch-and-link) so the return address is
@               in r14

		$CODE   COMPO+7,'doCONST',DoCONST,_SLINK
		pushD   tos
		ldr     tos, [r14]              @inline address from calling point
		$NEXT

@   doVALUE     ( -- x )
@               Run-time routine of VALUE. Return the value of VALUE word.
@               This is like an invocation of doCONST for a VARIABLE but
@               instead of returning the address of the variable, we return
@               the value of the variable -- in other words, there is another
@               level of indirection.

		$CODE   COMPO+7,'doVALUE',DoVALUE,_SLINK
		pushD   tos
		ldr     r0, [r14]
		ldr     tos, [r0]
		$NEXT

@   doCREATE    ( -- a-addr )
@               Run-time routine of CREATE. For CREATEd words with an
@               associated DOES>, get the address of the CREATEd word's data
@               space and execute the DOES> actions. For CREATEd word without
@               an associated DOES>, return the address of the CREATE'd word's
@               data space. A CREATEd word starts its execution through this
@               routine in exactly the same way as a colon definition uses
@               doLIST. In other words, we come here through a native machine
@               branch. For ARM, r14 holds the address of the next word at the
@               called point and fpc holds next word above that.
@
@               Structure of CREATEd word:
@                       | call-doCREATE | 0 or DOES> code addr | a-addr |
@
@               The DOES> address holds a native call to doLIST. This routine
@               doesn't alter the fpc. We never come back *here* so we never
@               need to preserve an address that would bring us back *here*. 
@
@               For ARM, r14 points to the "0 or DOES>" address. The DOES>
@
@               Example : myVARIABLE CREATE , DOES> @
@               56 myVARIABLE JIM
@               JIM \ stacks the address of the data cell that contains 56
@
@   : doCREATE    SWAP            \ switch BX and top of 8086 stack item
@                 DUP CELL+ @ SWAP @ ?DUP IF EXECUTE THEN @ COMPILE-ONLY
@
@                 $COLON  COMPO+8,'doCREATE',DoCREATE,_SLINK
@                 DW      SWAP,DUPP,CELLPlus,Fetch,SWAP,Fetch,QuestionDUP
@                 DW      ZBranch,DOCREAT1
@                 DW      EXECUTE
@ DOCREAT1:       DW      EXIT

		$CODE   COMPO+8,'doCREATE',DoCREATE,_SLINK
		pushD   tos
		ldr     r0, [r14], #CELLL       @ 0 or DOES> address
		ldr     tos, [r14]              @ a-addr
		orrs    r0, r0, #0              @ set flags..
		movne   pc, r0                  @ a DOES> address.. go there
						@ (and never come back)
		$NEXT                           @ no DOES> actions

@   doTO        ( x -- )
@               Run-time routine of TO. Store x at the address in the
@               following cell. The inline literal holds the address
@               to be modified.

		$CODE   COMPO+4,'doTO',DoTO,_SLINK
		@ get the address to be modified and point past
		ldr     r0, [fpc], #CELLL
		@ update to new value from tos
		str     tos, [r0]
		popD    tos
		$NEXT

@   doUSER      ( -- a-addr )
@               Run-time routine of USER. Return address of data space.
@               This is like doCONST but a variable offset is added to the
@               result. By changing the value at AddrUserP (which happens
@               on a taskswap) the whole set of user variables is switched
@               to the set for the new task.

		$CODE   COMPO+6,'doUSER',DoUSER,_SLINK
		pushD   tos
		ldr     tos, [r14]
		ldr     r0, = AddrUserP
		ldr     r1,[r0]
		add     tos, tos, r1
		$NEXT

		LTORG                           @ assembler-generated literals
						@ are stored here.

@   doLIST      ( -- ) ( R: -- nest-sys )
@               Process colon list.
@               The first word of a definition (the xt for the word) is a
@               native machine-code instruction for the target machine. For
@               high-level definitions, that code is emitted by xt, and
@               performs a call to doLIST. doLIST executes the list of xt that
@               make up the definition. The final xt in the definition is EXIT.
@               The address of the first xt to be executed is passed to doLIST
@               in a target-specific way. Two examples:
@               Z80, 8086: native machine call, leaves the return address on
@               the hardware stack pointer, which is used for the data stack.
@               ARM: branch-and-link, so the return address is in r14,
@               not on the data stack.

		$CODE   COMPO+6,'doLIST',DoLIST,_SLINK
		pushR   fpc                     @preserve forth PC
		mov     fpc, r14                @first xt of definition
		$NEXT

@   doLOOP      ( -- ) ( R: loop-sys1 -- | loop-sys2 )
@               Run time routine for LOOP.

		$CODE   COMPO+6,'doLOOP',DoLOOP,_SLINK
		popR    r0                      @loop count
		adds    r0, r0, #1
		bvs     %f01                    @overflow -> end loop
		pushR   r0                      @update loop count
		ldr     fpc, [fpc]              @get branch dest. to loop again
		$NEXT
01              add     fpc, fpc, #CELLL        @ignore branch offset
		popR    r0                      @@NAC what's this dropping?? -- can just bump rsp rather than doing memory access
		$NEXT

@   do+LOOP     ( n -- ) ( R: loop-sys1 -- | loop-sys2 )
@               Run time routine for +LOOP.

		$CODE   COMPO+7,'do+LOOP',DoPLOOP,_SLINK
		popR    r0                      @loop count
		adds    r0, r0, tos
		popD    tos
		bvs     %f01                    @overflow -> end loop
		pushR   r0                      @update loop count
		ldr     fpc, [fpc]              @loop again
		$NEXT
01              add     fpc, fpc, #CELLL        @ignore branch offset
		popR    r0                      @@NAC what's this dropping? -- can just bump rsp rather than doing memory access
		$NEXT

@   0branch     ( flag -- )
@               Branch if flag is zero.

		$CODE   COMPO+7,'0branch',ZBranch,_SLINK
		orrs    tos, tos, tos           @test top of stack
@ARM's cool conditional-execution saves pipeline-draining branches 
		addne   fpc, fpc, #CELLL        @don't branch, point past dest
		ldreq   fpc, [fpc]              @branch@ get destination
		popD    tos                     @tidy up the stack
		$NEXT

@   branch      ( -- )
@               Branch to an inline address.

		$CODE   COMPO+6,'branch',Branch,_SLINK
		ldr     fpc, [fpc]              @get branch destination
						@and go there
		$NEXT

@   rp@         ( -- a-addr )
@               Push the current RP to the data stack.

		$CODE   COMPO+3,'rp@',RPFetch,_SLINK
		pushD   tos
		mov     tos, rsp
		$NEXT

@   rp!         ( a-addr -- )
@               Set the return stack pointer.

		$CODE   COMPO+3,'rp!',RPStore,_SLINK
		mov     rsp, tos
		popD    tos
		$NEXT

@   sp@         ( -- a-addr )
@               Push the current data stack pointer.

		$CODE   3,'sp@',SPFetch,_SLINK
		pushD   tos
		mov     tos, dsp
		$NEXT

@   sp!         ( a-addr -- )
@               Set the data stack pointer.

		$CODE   3,'sp!',SPStore,_SLINK
		mov     dsp, tos
		popD    tos
		$NEXT

@   um+         ( u1 u2 -- u3 1|0 )
@               Add two unsigned numbers, return the sum and carry.

		$CODE   3,'um+',UMPlus,_SLINK
		popD    r1
		adds    r1, r1, tos             @combine
		eor     tos, tos, tos           @clear register
		adc     tos, tos, #0            @get carry flag
		pushD   r1                      @store sum
		$NEXT

@   1chars/     ( n1 -- n2 )
@               Calculate number of chars for n1 address units.
@
@   : 1chars/   1 CHARS / @     \ slow, very portable
@   : 1chars/   @               \ fast, must be redefined for each system

@               $COLON  7,'1chars/',OneCharsSlash,_SLINK
@               DW      EXIT

		$CODE   7,'1chars/',OneCharsSlash,_SLINK
		$NEXT

@@@@@@@@@@@@@@@@
@ Standard words - Processor-dependent definitions
@       32-bit Forth for ARM RISC
@@@@@@@@@@@@@@@@

@   ALIGN       ( -- )                          \ CORE
@               Align the data space pointer.
@
@   : ALIGN     hereVar DUP @ ALIGNED SWAP ! @

@               $COLON  5,'ALIGN',ALIGNN,_FLINK
@               DW      HereVar,DUPP,Fetch,ALIGNED,SWAP,Store,EXIT

		$CODE   5,'ALIGN',ALIGNN,_FLINK
		ldr     r0,=LocHereVar
		ldr     r1,[r0] @point to ROM or RAM pointer
		ldr     r2,[r1] @get its value
		add     r2,r2,#3
		and     r2,r2,#0fffffffch       @ round it down
		str     r2,[r1]
		$NEXT

@   ALIGNED     ( addr -- a-addr )              \ CORE
@               Align address to the cell boundary.
@
@   : ALIGNED   DUP 0 cell-size UM/MOD DROP DUP
@               IF cell-size SWAP - THEN + @    \ slow, very portable
@
@                 $COLON  7,'ALIGNED',ALIGNED,_FLINK
@                 DW      DUPP,Zero,DoLIT,CELLL
@                 DW      UMSlashMOD,DROP,DUPP
@                 DW      ZBranch,ALGN1
@                 DW      DoLIT,CELLL,SWAP,Minus
@ ALGN1           DW      Plus,EXIT

		$CODE   7,'ALIGNED',ALIGNED,_FLINK
		add     tos, tos,#3
		and     tos, tos, #0FFFFFFFCH @
		$NEXT

@ pack" is dependent of cell alignment.
@
@   pack"       ( c-addr u a-addr -- a-addr2 )
@               Place a string c-addr u at a-addr and gives the next
@               cell-aligned address. Fill the rest of the last cell with
@               null character.
@
@   : pack"     2DUP SWAP CHARS + CHAR+ DUP >R  \ ca u aa aa+u+1
@               1 CHARS - 0 SWAP !              \ fill 0 at the end of string
@               2DUP C! CHAR+ SWAP              \ c-addr a-addr+1 u
@               CHARS MOVE R> @ COMPILE-ONLY

@		$COLON  COMPO+5,'pack"',PackQuote,_SLINK
@		DW      TwoDUP,SWAP,CHARS,Plus,CHARPlus,DUPP,ToR
@		DW      DoLIT,CHARR,Minus,Zero,SWAP,Store
@		DW      TwoDUP,CStore,CHARPlus,SWAP
@		DW      CHARS,MOVE,RFrom,EXIT

                $CODE   COMPO+5,'pack"',PackQuote,_SLINK
                @assume strings don't overlap
                popD    r0      @u
                popD    r1      @c-addr
                strb    r0,[tos],#CHARR @store length
01              ldrb    r2,[r1], #CHARR
                strb    r2,[tos], #CHARR
                subs    r0, r0, #CHARR
                bne     %b01
                @next address is in tos. Need to align, filling any
                @space with 0. r0 holds 0
		and	r1,tos,#3 @number of runt bytes
		rsb	r1,r1,#4
		cmp	r1,#4	  @EQ if aligned
02              strneb  r0,[tos], #CHARR
                subnes  r1,r1,#1
                bne     %b02
@drop through if no bytes to fill or at end
                $NEXT

@   CELLS       ( n1 -- n2 )                    \ CORE
@               Calculate number of address units for n1 cells.
@
@   : CELLS     cell-size * @   \ slow, very portable
@   : CELLS     2* @            \ fast, must be redefined for each system

@               $COLON  5,'CELLS',CELLS,_FLINK
@               DW      TwoStar,TwoStar,EXIT    @multiply by 4 for ARM

		$CODE   5,'CELLS',CELLS,_FLINK
		mov     tos, tos, lsl #2        @multiply by 4
		$NEXT

@   CHARS       ( n1 -- n2 )                    \ CORE
@               Calculate number of address units for n1 characters.
@
@   : CHARS     char-size * @   \ slow, very portable
@   : CHARS     @               \ fast, must be redefined for each system

@               $COLON  5,'CHARS',CHARS,_FLINK
@               DW      EXIT

		$CODE   5,'CHARS',CHARS,_FLINK
		$NEXT

@   !           ( x a-addr -- )                 \ CORE
@               Store x at a aligned address.

		$CODE   1,'!',Store,_FLINK
		popD    r1                      @char to store
		str     r1, [tos]
		popD    tos                     @clear up stack
		$NEXT

@   0<          ( n -- flag )                   \ CORE
@               Return true if n is negative.

		$CODE   2,'0<',ZeroLess,_FLINK
		mov     r0, #0                  @get zeroes for dummy arg
		add     tos, r0, tos, asr #32   @echo bit 32 value through r1
		$NEXT

@   0=          ( x -- flag )                   \ CORE
@               Return true if x is zero.

		$CODE   2,'0=',ZeroEquals,_FLINK
		cmp     tos, #0
		ldreq   tos,=TRUEE
		ldrne   tos,=FALSEE
		$NEXT

@   2*          ( x1 -- x2 )                    \ CORE
@               Bit-shift left, filling the least significant bit with 0.

		$CODE   2,'2*',TwoStar,_FLINK
		mov     tos, tos, lsl #1
		$NEXT

@   2/          ( x1 -- x2 )                    \ CORE
@               Bit-shift right, leaving the most significant bit unchanged.

		$CODE   2,'2/',TwoSlash,_FLINK
		mov     tos, tos, asr #1
		$NEXT

@   >R          ( x -- ) ( R: -- x )            \ CORE
@               Move top of the data stack item to the return stack.

		$CODE   COMPO+2,'>R',ToR,_FLINK
		pushR   tos
		popD    tos
		$NEXT

@   @           ( a-addr -- x )                 \ CORE
@               Push the contents at a-addr to the data stack.

		$CODE   1,'@',Fetch,_FLINK
		ldr     tos, [tos]
		$NEXT

@   AND         ( x1 x2 -- x3 )                 \ CORE
@               Bitwise AND.

		$CODE   3,'AND',ANDD,_FLINK
		popD    r1
		and     tos, tos, r1
		$NEXT

@   C!          ( char c-addr -- )              \ CORE
@               Store char at c-addr.

		$CODE   2,'C!',CStore,_FLINK
		popD    r1                      @char to store
		strb    r1, [tos]
		popD    tos                     @clear up stack
		$NEXT

@   C@          ( c-addr -- char )              \ CORE
@               Fetch the character stored at c-addr.

		$CODE   2,'C@',CFetch,_FLINK
		ldrb    tos, [tos]
		$NEXT

@   DROP        ( x -- )                        \ CORE
@               Discard top stack item.

		$CODE   4,'DROP',DROP,_FLINK
		popD    tos
		$NEXT

@   DUP         ( x -- x x )                    \ CORE
@               Duplicate the top stack item.

		$CODE   3,'DUP',DUPP,_FLINK
		pushD   tos
		$NEXT

@   EXECUTE     ( i*x xt -- j*x )               \ CORE
@               Perform the semantics indentified by execution token, xt.

		$CODE   7,'EXECUTE',EXECUTE,_FLINK
		mov     r1,tos
		popD    tos
		mov     pc,r1                   @jump to the code address

@   EXIT        ( -- ) ( R: nest-sys -- )       \ CORE
@               Return control to the calling definition.

		$CODE   COMPO+4,'EXIT',EXIT,_FLINK
		popR    fpc                     @where call doLIST left it
		$NEXT

@   MOVE        ( addr1 addr2 u -- )            \ CORE
@               Copy u address units from addr1 to addr2 if u is greater
@               than zero. This word is CODE defined since no other Standard
@               words can handle address unit directly.

		$CODE   4,'MOVE',MOVE,_FLINK
		popD    r0              @dest
		popD    r1              @source
		cmp     r0, r1
		bmi     %f01            @copy from end backwards
02              ldrb    r2, [r1], #1
		strb    r2, [r0], #1
		subs    tos, tos, #1
		bne     %b02
		popD    tos
		$NEXT
01              add     r0, r0, tos     @point past the last bytes
		add     r1, r1, tos
03              ldrb    r2, [r1, #-1]!  @load with predecrement
		strb    r2, [r0, #-1]!
		subs    tos, tos, #1
		bne     %b03
		popD    tos
		$NEXT

@   OR          ( x1 x2 -- x3 )                 \ CORE
@               Return bitwise inclusive-or of x1 with x2.

		$CODE   2,'OR',ORR,_FLINK
		popD    r1
		orr     tos, tos, r1
		$NEXT

@   OVER        ( x1 x2 -- x1 x2 x1 )           \ CORE
@               Copy second stack item to top of the stack.

		$CODE   4,'OVER',OVER,_FLINK
		ldr     r1, [dsp]               @copy 2nd stack item
		pushD   tos
		mov     tos, r1
		$NEXT

@   R>          ( -- x ) ( R: x -- )            \ CORE
@               Move x from the return stack to the data stack.

		$CODE   COMPO+2,'R>',RFrom,_FLINK
		pushD   tos
		popR    tos
		$NEXT

@   R@          ( -- x ) ( R: x -- x )          \ CORE
@               Copy top of return stack to the data stack.

		$CODE   COMPO+2,'R@',RFetch,_FLINK
		pushD   tos
		ldr     tos, [rsp]
		$NEXT

@   SWAP        ( x1 x2 -- x2 x1 )              \ CORE
@               Exchange top two stack items.

		$CODE   4,'SWAP',SWAP,_FLINK
		popD    r1
		pushD   tos
		mov     tos,r1
		$NEXT

@   XOR         ( x1 x2 -- x3 )                 \ CORE
@               Bitwise exclusive OR.

		$CODE   3,'XOR',XORR,_FLINK
		popD    r1
		eor     tos, tos, r1
		$NEXT

@@@@@@@@@@@@@@@@
@ System constants and variables
@@@@@@@@@@@@@@@@

@   var0        ( -- a-addr )
@               Start of system variable area.

		$CONST  4,'var0',VarZero,RAM0,_SLINK

@   sysVar0     ( -- a-addr )
@               Start of initial value table of system variables.

		$CONST  7,'sysVar0',SysVar0,UZERO,_SLINK

@   sysVar0End  ( -- a-addr )
@               End of initial value table of system variables.

		$CONST  10,'sysVar0End',SysVar0End,ULAST,_SLINK

@   'ekey?      ( -- a-addr )
@               Execution vector of EKEY?.

		$VALUE  6,"'ekey?",TickEKEYQ,_SLINK
AddrTEKEYQ      .equ     _VAR -CELLL

@   'ekey       ( -- a-addr )
@               Execution vector of EKEY.

		$VALUE  5,"'ekey",TickEKEY,_SLINK
AddrTEKEY       .equ     _VAR -CELLL

@   'emit?      ( -- a-addr )
@               Execution vector of EMIT?.

		$VALUE  6,"'emit?",TickEMITQ,_SLINK
AddrTEMITQ      .equ     _VAR -CELLL

@   'emit       ( -- a-addr )
@               Execution vector of EMIT.

		$VALUE  5,"'emit",TickEMIT,_SLINK
AddrTEMIT       .equ     _VAR -CELLL

@   'init-i/o   ( -- a-addr )
@               Execution vector to initialize input/output devices.

		$VALUE  9,"'init-i/o",TickINIT_IO,_SLINK

@   'prompt     ( -- a-addr )
@               Execution vector of '.prompt'.

		$VALUE  7,"'prompt",TickPrompt,_SLINK
AddrTprompt     .equ     _VAR -CELLL

@   'boot       ( -- a-addr )
@               Execution vector of COLD.

		$VALUE  5,"'boot",TickBoot,_SLINK

@   IOBYTES     ( -- a-addr )
@               Identify i/o options

		$VALUE  7,"IOBYTES",IOBYTESS,_SLINK
AddrIOBYTES     .equ     _VAR -CELLL

@   SOURCE-ID   ( -- 0 | -1 )                   \ CORE EXT
@               Identify the input source. -1 for string (via EVALUATE) and
@               0 for user input device.

		$VALUE  9,'SOURCE-ID',SOURCE_ID,_FLINK
AddrSOURCE_ID   .equ     _VAR -CELLL

@   cpVar       ( -- a-addr )
@               Point to the top of the code dictionary.

		$VALUE  5,'cpVar',CPVar,_SLINK
AddrCPVar       .equ     _VAR -CELLL

@   npVar       ( -- a-addr )
@               Point to the bottom of the name dictionary.

		$VALUE  5,'npVar',NPVar,_SLINK
AddrNPVar       .equ     _VAR -CELLL

@   hereVar     ( -- a-addr )
@               Point to the RAM/ROM data space pointer. Used by , or ALLOT.

		$VALUE  7,'hereVar',HereVar,_SLINK

@   'doWord     ( -- a-addr )
@               Execution vectors for 'interpret'.

		$VAR    7,"'doWord",TickDoWord,_SLINK
_VAR            SETA _VAR +5*CELLL

@   BASE        ( -- a-addr )                   \ CORE
@               Return the address of the radix base for numeric I/O.

		$VAR    4,'BASE',BASE,_FLINK

@   THROWMsgTbl ( -- a-addr )                   \ CORE
@               Return the address of the THROW message table.

		$CONST  11,'THROWMsgTbl',THROWMsgTbl,AddrTHROWMsgTbl,_SLINK

@   ROMB        ( -- a-addr )
@               Bottom of free ROM area.

		$VAR    4,'ROMB',ROMB,_SLINK
AddrROMB        .equ     _VAR -CELLL

@   ROMT        ( -- a-addr )
@               Top of free ROM area.

		$VAR    4,'ROMT',ROMT,_SLINK
AddrROMT        .equ     _VAR -CELLL

@   RAMB        ( -- a-addr )
@               Bottom of free RAM area.

		$VAR    4,'RAMB',RAMB,_SLINK
AddrRAMB        .equ     _VAR -CELLL

@   RAMT        ( -- a-addr )
@               Top of free RAM area.

		$VAR    4,'RAMT',RAMT,_SLINK
AddrRAMT        .equ     _VAR -CELLL

@   bal         ( -- n )
@               Return the depth of control-flow stack.

		$VALUE  3,'bal',Bal,_SLINK
AddrBal         .equ     _VAR -CELLL

@   notNONAME?  ( -- f )
@               Used by '@' whether to do 'linkLast' or not

		$VALUE  10,'notNONAME?',NotNONAMEQ,_SLINK
AddrNotNONAMEQ  .equ     _VAR -CELLL

@   rakeVar     ( -- a-addr )
@               Used by 'rake' to gather LEAVE.

		$VAR   7,'rakeVar',RakeVar,_SLINK

@   #order      ( -- a-addr )
@               Hold the search order stack depth.

		$VAR    6,'#order',NumberOrder,_SLINK
_VAR            SETA _VAR +OrderDepth*CELLL   @search order stack

@   current     ( -- a-addr )
@               Point to the wordlist to be extended.

		$VAR    7,'current',Current,_SLINK

@   FORTH-WORDLIST   ( -- wid )                 \ SEARCH
@               Return wid of Forth wordlist.

		$VAR    14,'FORTH-WORDLIST',FORTH_WORDLIST,_FLINK
FORTH_WORDLISTAddr      .equ     _VAR -CELLL
@@@NAC can't use _NAME .. goal is to get the address of the counted string?
@@@FORTH_WORDLISTName      .equ     _NAME +2*CELLL
		$GET_NAME "+2*CELLL" FORTH_WORDLISTName

_VAR            SETA _VAR +2*CELLL

@   NONSTANDARD-WORDLIST   ( -- wid )
@               Return wid of non-standard wordlist.

		$VAR    20,'NONSTANDARD-WORDLIST',NONSTANDARD_WORDLIST,_FLINK
NONSTANDARD_WORDLISTAddr        .equ     _VAR -CELLL
@@@NAC can't use _NAME
@@@NONSTANDARD_WORDLISTName        .equ     _NAME +2*CELLL
		$GET_NAME "+2*CELLL" NONSTANDARD_WORDLISTName

_VAR            SETA _VAR +2*CELLL
_VAR            SETA _VAR +3*(MaxWLISTS-2)*CELLL

@   envQList    ( -- wid )
@               Return wid of ENVIRONMENT? string list. Never put this wid in
@               search-order. It should be used only by SET-CURRENT to add new
@               environment query string after addition of a complete wordset.

		$VAR    8,'envQList',EnvQList,_SLINK

@   userP       ( -- a-addr )
@               Return address of USER variable area of current task.

		$VAR    5,'userP',UserP,_SLINK
@NAC: My version to set AddrUserP seems simpler and just as portable
AddrUserP       .equ _VAR - CELLL
@_CODE   = $
@ORG _VAR -CELLL
@AddrUserP       DW      ?
@ORG _CODE

SysTask         .equ     _VAR-0
_VAR            SETA _VAR + CELLL

SysUser1        .equ     _VAR-0                  @user1
_VAR            SETA _VAR + CELLL             
SysTaskName     .equ     _VAR-0                  @taskName
_VAR            SETA _VAR + CELLL             
SysThrowFrame   .equ     _VAR-0                  @throwFrame
_VAR            SETA _VAR + CELLL
SysStackTop     .equ     _VAR-0                  @stackTop
_VAR            SETA _VAR + CELLL
SysStatus       .equ     _VAR-0                  @status
_VAR            SETA _VAR + CELLL
SysUserP        .equ     _VAR-0
SysFollower     .equ     _VAR-0                  @follower
_VAR            SETA _VAR + CELLL
_VAR            SETA _VAR + CELLL             @SP0 for system task
_VAR            SETA _VAR + CELLL             @RP0 for system task

@   trapfpc     ( -- a-addr )
@               Return address of a variable holding trap address for
@               microdebugger

		$VAR    7,'trapfpc',Trapfpc,_SLINK
AddrTrapfpc     .equ     _VAR -CELLL


@   SystemTask  ( -- a-addr )
@               Return system task's tid.

		$CONST  10,'SystemTask',SystemTask,SysTask,_SLINK
@@@NAC what's it *for* and what is it doing in the name dictionary?
@@@SystemTaskName  .equ     _NAME-0
		$GET_NAME "+0" SystemTaskName

@   follower    ( -- a-addr )
@               Point next task's 'status' USER variable.

		$USER   8,'follower',Follower,SysFollower-SysUserP,_SLINK

@   status      ( -- a-addr )
@               Status of current task. Point 'pass' or 'wake'.

		$USER   6,'status',Status,SysStatus-SysUserP,_SLINK

@   stackTop    ( -- a-addr )
@               Store current task's top of stack position.

		$USER   8,'stackTop',StackTop,SysStackTop-SysUserP,_SLINK

@   throwFrame  ( -- a-addr )
@               THROW frame for CATCH and THROW need to be saved for eack task.

		$USER   10,'throwFrame',ThrowFrame,SysThrowFrame-SysUserP,_SLINK

@   taskName    ( -- a-addr )
@               Current task's task ID.

		$USER   8,'taskName',TaskName,SysTaskName-SysUserP,_SLINK

@   user1       ( -- a-addr )
@               One free USER variable for each task.

		$USER   5,'user1',User1,SysUser1-SysUserP,_SLINK

@ ENVIRONMENT? strings can be searched using SEARCH-WORDLIST and can be
@ EXECUTEd. This wordlist is completely hidden to Forth system except
@ ENVIRONMENT? .

		$ENVIR  3,'CPU'
		DW      DoLIT,CPUStr,COUNT,EXIT

		$ENVIR  5,'model'
		DW      DoLIT,ModelStr,COUNT,EXIT

		$ENVIR  7,'version'
		DW      DoLIT,VersionStr,COUNT,EXIT

		$ENVIR  15,'/COUNTED-STRING'
		DW      DoLIT,MaxString,EXIT

		$ENVIR  5,'/HOLD'
		DW      DoLIT,PADSize,EXIT

		$ENVIR  4,'/PAD'
		DW      DoLIT,PADSize,EXIT

		$ENVIR  17,'ADDRESS-UNIT-BITS'
		DW      DoLIT,8,EXIT

		$ENVIR  4,'CORE'
		DW      DoLIT,TRUEE,EXIT

		$ENVIR  7,'FLOORED'
		DW      DoLIT,TRUEE,EXIT

		$ENVIR  8,'MAX-CHAR'
		DW      DoLIT,MaxChar,EXIT      @max value of character set

		$ENVIR  5,'MAX-D'
		DW      DoLIT,MaxUnsigned,DoLIT,MaxSigned,EXIT

		$ENVIR  5,'MAX-N'
		DW      DoLIT,MaxSigned,EXIT

		$ENVIR  5,'MAX-U'
		DW      DoLIT,MaxUnsigned,EXIT

		$ENVIR  6,'MAX-UD'
		DW      DoLIT,MaxUnsigned,DoLIT,MaxUnsigned,EXIT

		$ENVIR  18,'RETURN-STACK-CELLS'
		DW      DoLIT,RTCells,EXIT

		$ENVIR  11,'STACK-CELLS'
		DW      DoLIT,DTCells,EXIT

		$ENVIR  9,'EXCEPTION'
		DW      DoLIT,TRUEE,EXIT

		$ENVIR  13,'EXCEPTION-EXT'
		DW      DoLIT,TRUEE,EXIT

		$ENVIR  9,'WORDLISTS'
		DW      DoLIT,OrderDepth,EXIT

@@@@@@@@@@@@@@@@
@ Non-Standard words - Colon definitions
@@@@@@@@@@@@@@@@

@   (')         ( "<spaces>name" -- xt 1 | xt -1 )
@               Parse a name, find it and return execution token and
@               -1 or 1 ( IMMEDIATE) if found
@
@   : (')       PARSE-WORD search-word ?DUP IF NIP EXIT THEN
@               errWord 2!      \ if not found error
@               -13 THROW @     \ undefined word

		$COLON  3,"(')",ParenTick,_SLINK
		DW      PARSE_WORD,Search_word,QuestionDUP,ZBranch,PTICK1
		DW      NIP,EXIT
PTICK1          DW      ErrWord,TwoStore,DoLIT,-13,THROW

@   (d.)        ( d -- c-addr u )
@               Convert a double number to a string.
@
@   : (d.)      SWAP OVER  DUP 0< IF  DNEGATE  THEN
@               <#  #S ROT SIGN  #> @

		$COLON  4,'(d.)',ParenDDot,_SLINK
		DW      SWAP,OVER,DUPP,ZeroLess,ZBranch,PARDD1
		DW      DNEGATE
PARDD1          DW      LessNumberSign,NumberSignS,ROT
		DW      SIGN,NumberSignGreater,EXIT

@   .ok         ( -- )
@               Display 'ok'.
@
@   : .ok       ." ok" @

		$COLON  3,'.ok',DotOK,_SLINK
		$INSTR  'ok'
		DW      TYPEE,EXIT

@   .prompt         ( -- )
@               Display Forth prompt. This word is vectored.
@
@   : .prompt   'prompt EXECUTE @

@               $COLON  7,'.prompt',DotPrompt,_SLINK
@               DW      TickPrompt,EXECUTE,EXIT

		$CODE   7,'.prompt',DotPrompt,_SLINK
		ldr     r0,=AddrTprompt
		ldr     r1,[r0]
		mov     pc,r1
	
@   0           ( -- 0 )
@               Return zero.

@               $CONST  1,'0',Zero,0,_SLINK

		$CODE   1,'0',Zero,_SLINK
		pushD   tos
		mov     tos,#0
		$NEXT

@   1           ( -- 1 )
@               Return one.

@               $CONST  1,'1',One,1,_SLINK

		$CODE   1,'1',One,_SLINK
		pushD   tos
		mov     tos,#1
		$NEXT

@   -1          ( -- -1 )
@               Return -1.

@               $CONST  2,'-1',MinusOne,-1,_SLINK

		$CODE   2,'-1',MinusOne,_SLINK
		pushD   tos
		mov     tos,#-1
		$NEXT

@   abort"msg   ( -- a-addr )
@               Abort" error message string address.

		$VAR    9,'abort"msg',AbortQMsg,_SLINK
_VAR            SETA _VAR +CELLL

@   bal+        ( -- )
@               Increase bal by 1.
@
@   : bal+      bal 1+ TO bal @

@               $COLON  4,'bal+',BalPlus,_SLINK 
@               DW      Bal,OnePlus,DoTO,AddrBal,EXIT

		$CODE   4,'bal+',BalPlus,_SLINK
		ldr     r0,=AddrBal
		ldr     r1,[r0]
		add     r1,r1,#1
		str     r1,[r0]
		$NEXT

@   bal-        ( -- )
@               Decrease bal by 1.
@
@   : bal-      bal 1- TO bal @

@               $COLON  4,'bal-',BalMinus,_SLINK
@               DW      Bal,OneMinus,DoTO,AddrBal,EXIT

		$CODE   4,'bal-',BalMinus,_SLINK
		ldr     r0,=AddrBal
		ldr     r1,[r0]
		sub     r1,r1,#1
		str     r1,[r0]
		$NEXT

		LTORG

@   cell-       ( a-addr1 -- a-addr2 )
@               Return previous aligned cell address.
@
@   : cell-     -(cell-size) + @

@               $COLON  5,'cell-',CellMinus,_SLINK
@               DW      DoLIT,0-CELLL,Plus,EXIT

		$CODE   5,'cell-',CellMinus,_SLINK
		sub     tos, tos, #CELLL
		$NEXT           

@   COMPILE-ONLY   ( -- )
@               Make the most recent definition an compile-only word.
@
@   : COMPILE-ONLY   lastName [ =comp ] LITERAL OVER @ OR SWAP ! @

@               $COLON  12,'COMPILE-ONLY',COMPILE_ONLY,_SLINK
@               DW      LastName,DoLIT,COMPO,OVER,Fetch,ORR,SWAP,Store,EXIT

		$CODE   12,'COMPILE-ONLY',COMPILE_ONLY,_SLINK
		ldr     r0,=AddrNPVar
		ldr     r1,[r0]
		ldr     r2,[r1]
		add     r2,r2,#(CELLL*2)        @Lastname
		ldr     r3,[r2]                 @get length
		orr     r3,r3,#COMPO            @set flag
		str     r3,[r2]
		$NEXT

		LTORG

@   doS"        ( u -- c-addr u )
@               Run-time function of S" .
@
@   : doS"      R> SWAP 2DUP + ALIGNED >R @ COMPILE-ONLY

@		$COLON  COMPO+4,'doS"',DoSQuote,_SLINK
@		DW      RFrom,SWAP,TwoDUP,Plus,ALIGNED,ToR,EXIT

		$CODE   COMPO+4,'doS"',DoSQuote,_SLINK
		@in the colon case the 'next address' is on the
		@return stack. In the code case it is still in fpc
		pushD   fpc             @start of string
		add     fpc,fpc,tos     @point to end of string
		add     fpc,fpc,#3      @and align
		and     fpc,fpc,#0fffffffch @
		$NEXT

@   doDO        ( n1|u1 n2|u2 -- ) ( R: -- n1 n2-n1-max_negative )
@               Run-time funtion of DO.
@
@   : doDO      >R max-negative + R> OVER - SWAP R> SWAP >R SWAP >R >R @

		$COLON  COMPO+4,'doDO',DoDO,_SLINK
		DW      ToR,DoLIT,MaxNegative,Plus,RFrom
		DW      OVER,Minus,SWAP,RFrom,SWAP,ToR,SWAP,ToR,ToR,EXIT

@   errWord     ( -- a-addr )
@               Last found word. To be used to display the word causing error.

		$VAR   7,'errWord',ErrWord,_SLINK
_VAR            SETA _VAR +CELLL

@   head,       ( xt "<spaces>name" -- )
@               Parse a word and build a dictionary entry using xt and name.
@
@   : head,     PARSE-WORD DUP 0=
@               IF errWord 2! -16 THROW THEN
@                               \ attempt to use zero-length string as a name
@               DUP =mask > IF -19 THROW THEN   \ definition name too long
@               2DUP GET-CURRENT SEARCH-WORDLIST  \ name exist?
@               IF DROP ." redefine " 2DUP TYPE SPACE THEN \ warn if redefined
@               npVar @ OVER CELL+ - ALIGNED
@               DUP >R pack" DROP R>            \ pack the name in dictionary
@               cell- GET-CURRENT @ OVER !      \ build wordlist link
@               cell- DUP npVar !  ! @          \ adjust name space pointer
@                                               \ and store xt at code field

		$COLON  5,'head,',HeadComma,_SLINK
		DW      PARSE_WORD,DUPP,ZBranch,HEADC1
		DW      DUPP,DoLIT,MASKK,GreaterThan,ZBranch,HEADC3
		DW      DoLIT,-19,THROW
HEADC3          DW      TwoDUP,GET_CURRENT,SEARCH_WORDLIST,ZBranch,HEADC2
		DW      DROP
		$INSTR  'redefine '
		DW      TYPEE,TwoDUP,TYPEE,SPACE
HEADC2          DW      NPVar,Fetch,OVER,CELLPlus,Minus,ALIGNED
		DW      DUPP,ToR,PackQuote,DROP,RFrom
		DW      CellMinus,GET_CURRENT,Fetch,OVER,Store
		DW      CellMinus,DUPP,NPVar,Store,Store,EXIT
HEADC1          DW      ErrWord,TwoStore,DoLIT,-16,THROW

@   hld         ( -- a-addr )
@               Hold a pointer in building a numeric output string.

		$VAR    3,'hld',HLD,_SLINK

@   interpret   ( i*x -- j*x )
@               Intrepret input string.
@
@   : interpret BEGIN  DEPTH 0< IF -4 THROW THEN        \ stack underflow
@                      PARSE-WORD DUP
@               WHILE  2DUP errWord 2!
@                      search-word          \ ca u 0 | xt f -1 | xt f 1
@                      DUP IF
@                        SWAP STATE @ OR 0= \ compile-only in interpretation
@                        IF -14 THROW THEN  \ interpreting a compile-only word
@                      THEN
@                      1+ 2* STATE @ 1+ + CELLS 'doWord + @ EXECUTE
@               REPEAT 2DROP @

		$COLON  9,'interpret',Interpret,_SLINK
INTERP1         DW      DEPTH,ZeroLess,ZBranch,INTERP2
		DW      DoLIT,-4,THROW
INTERP2         DW      PARSE_WORD,DUPP,ZBranch,INTERP3
		DW      TwoDUP,ErrWord,TwoStore
		DW      Search_word,DUPP,ZBranch,INTERP5
		DW      SWAP,STATE,Fetch,ORR,ZBranch,INTERP4
INTERP5         DW      OnePlus,TwoStar,STATE,Fetch,OnePlus,Plus,CELLS
		DW      TickDoWord,Plus,Fetch,EXECUTE
		DW      Branch,INTERP1
INTERP3         DW      TwoDROP,EXIT
INTERP4         DW      DoLIT,-14,THROW

@   optiCOMPILE, ( xt -- )
@               Optimized COMPILE, . Reduce doLIST ... EXIT sequence if
@               xt is COLON definition which contains less than two words.
@
@   : optiCOMPILE,
@               DUP ?call ['] doLIST = IF
@                   DUP @ ['] EXIT = IF         \ if first word is EXIT
@                     2DROP EXIT THEN
@                   DUP CELL+ @ ['] EXIT = IF   \ if second word is EXIT
@                     @ DUP ['] doLIT XOR  \ make sure it is not literal value
@                     IF SWAP THEN THEN
@               THEN THEN DROP COMPILE, @

		$COLON  12,'optiCOMPILE,',OptiCOMPILEComma,_SLINK
		DW      DUPP,QCall,DoLIT,DoLIST,Equals,ZBranch,OPTC2
		DW      DUPP,Fetch,DoLIT,EXIT,Equals,ZBranch,OPTC1
		DW      TwoDROP,EXIT
OPTC1           DW      DUPP,CELLPlus,Fetch,DoLIT,EXIT,Equals,ZBranch,OPTC2
		DW      Fetch,DUPP,DoLIT,DoLIT,XORR,ZBranch,OPTC2
		DW      SWAP
OPTC2           DW      DROP,COMPILEComma,EXIT

@   singleOnly  ( c-addr u -- x )
@               Handle the word not found in the search-order. If the string
@               is legal, leave a single cell number in interpretation state.
@
@   : singleOnly
@               0 DUP 2SWAP OVER C@ [CHAR] -
@               = DUP >R IF 1 /STRING THEN
@               >NUMBER IF -13 THROW THEN       \ undefined word
@               2DROP R> IF NEGATE THEN @

		$COLON  10,'singleOnly',SingleOnly,_SLINK
		DW      Zero,DUPP,TwoSWAP,OVER,CFetch,DoLIT,'-'
		DW      Equals,DUPP,ToR,ZBranch,SINGLEO4
		DW      One,SlashSTRING
SINGLEO4        DW      ToNUMBER,ZBranch,SINGLEO1
		DW      DoLIT,-13,THROW
SINGLEO1        DW      TwoDROP,RFrom,ZBranch,SINGLEO2
		DW      NEGATE
SINGLEO2        DW      EXIT

@   singleOnly, ( c-addr u -- )
@               Handle the word not found in the search-order. Compile a
@               single cell number in compilation state.
@
@   : singleOnly,
@               singleOnly LITERAL @

		$COLON  11,'singleOnly,',SingleOnlyComma,_SLINK
		DW      SingleOnly,LITERAL,EXIT

@   (doubleAlso) ( c-addr u -- x 1 | x x 2 )
@               If the string is legal, leave a single or double cell number
@               and size of the number.
@
@   : (doubleAlso)
@               0 DUP 2SWAP OVER C@ [CHAR] -
@               = DUP >R IF 1 /STRING THEN
@               >NUMBER ?DUP
@               IF   1- IF -13 THROW THEN     \ more than one char is remained
@                    DUP C@ [CHAR] . XOR      \ last char is not '.'
@                    IF -13 THROW THEN        \ undefined word
@                    R> IF DNEGATE THEN
@                    2 EXIT               THEN
@               2DROP R> IF NEGATE THEN       \ single number
@               1 @

		$COLON  12,'(doubleAlso)',ParenDoubleAlso,_SLINK
		DW      Zero,DUPP,TwoSWAP,OVER,CFetch,DoLIT,'-'
		DW      Equals,DUPP,ToR,ZBranch,DOUBLEA1
		DW      One,SlashSTRING
DOUBLEA1        DW      ToNUMBER,QuestionDUP,ZBranch,DOUBLEA4
		DW      OneMinus,ZBranch,DOUBLEA3
DOUBLEA2        DW      DoLIT,-13,THROW
DOUBLEA3        DW      CFetch,DoLIT,'.',Equals,ZBranch,DOUBLEA2
		DW      RFrom,ZBranch,DOUBLEA5
		DW      DNEGATE
DOUBLEA5        DW      DoLIT,2,EXIT            @ result is a double
DOUBLEA4        DW      TwoDROP,RFrom,ZBranch,DOUBLEA6
		DW      NEGATE
DOUBLEA6        DW      One,EXIT                @ result is a single

@   doubleAlso  ( c-addr u -- x | x x )
@               Handle the word not found in the search-order. If the string
@               is legal, leave a single or double cell number in
@               interpretation state.
@
@   : doubleAlso
@               (doubleAlso) DROP @

		$COLON  10,'doubleAlso',DoubleAlso,_SLINK
		DW      ParenDoubleAlso,DROP,EXIT

@   doubleAlso, ( c-addr u -- )
@               Handle the word not found in the search-order. If the string
@               is legal, compile a single or double cell number in
@               compilation state.
@
@   : doubleAlso,
@               (doubleAlso) 1- IF SWAP LITERAL THEN LITERAL @

		$COLON  11,'doubleAlso,',DoubleAlsoComma,_SLINK
		DW      ParenDoubleAlso,OneMinus,ZBranch,DOUBC1
		DW      SWAP,LITERAL
DOUBC1          DW      LITERAL,EXIT

@   -.          ( -- )
@               You don't need this word unless you care that '-.' returns
@               double cell number 0. Catching illegal number '-.' in this way
@               is easier than make 'interpret' catch this exception.
@
@   : -.        -13 THROW @ IMMEDIATE   \ undefined word

		$COLON  IMMED+2,'-.',MinusDot,_SLINK
		DW      DoLIT,-13,THROW

@   lastName    ( -- c-addr )
@               Return the address of the last definition name.
@
@   : lastName  npVar @ CELL+ CELL+ @

@               $COLON  8,'lastName',LastName,_SLINK
@               DW      NPVar,Fetch,CELLPlus,CELLPlus,EXIT

		$CODE   8,'lastName',LastName,_SLINK
		pushD   tos
		ldr     r0,=AddrNPVar
		ldr     r1,[r0]
		ldr     tos,[r1]
		add     tos,tos,#(CELLL*2)
		$NEXT

@   linkLast    ( -- )
@               Link the word being defined to the current wordlist.
@               Do nothing if the last definition is made by :NONAME .
@
@   : linkLast  lastName GET-CURRENT ! @

@               $COLON  8,'linkLast',LinkLast,_SLINK
@               DW      LastName,GET_CURRENT,Store,EXIT

		$CODE   8,'linkLast',LinkLast,_SLINK
		ldr     r0,=AddrNPVar
		ldr     r1,[r0]
		ldr     r2,[r1]
		add     r2,r2,#(CELLL*2) @address of last definition name
		ldr     r0,=LocCurrent
		ldr     r1,[r0]         @wid of compilation wordlist
		str     r2,[r1]         @gets bumped up by new addition
		$NEXT

@   name>xt     ( c-addr -- xt )
@               Return execution token using counted string at c-addr.
@
@   : name>xt   cell- cell- @ @

@               $COLON  7,'name>xt',NameToXT,_SLINK
@               DW      CellMinus,CellMinus,Fetch,EXIT

		$CODE   7,'name>xt',NameToXT,_SLINK
		sub     r0,tos,#(CELLL*2)       @point back past link to xt
		ldr     tos,[r0]                @get the xt
		$NEXT

@   PARSE-WORD  ( "<spaces>ccc<space>" -- c-addr u )
@               Skip leading spaces and parse a word. Return the name.
@
@   : PARSE-WORD   BL skipPARSE @

@               $COLON  10,'PARSE-WORD',PARSE_WORD,_SLINK
@               DW      BLank,SkipPARSE,EXIT

		$CODE   10,'PARSE-WORD',PARSE_WORD,_SLINK
		pushD   tos
		mov     tos,#SPC
		b       SkipPARSE

@   pipe        ( -- ) ( R: xt -- )
@               Connect most recently defined word to code following DOES>.
@               Structure of CREATEd word:
@                       | call-doCREATE | 0 or DOES> code addr | a-addr |
@
@   : pipe      lastName name>xt ?call DUP IF   \ code-addr xt2
@                   ['] doCREATE = IF
@                   R> SWAP !           \ change DOES> code of CREATEd word
@                   EXIT
@               THEN THEN
@               -32 THROW       \ invalid name argument, no-CREATEd last name
@               @ COMPILE-ONLY

		$COLON  COMPO+4,'pipe',Pipe,_SLINK
		DW      LastName,NameToXT,QCall,DUPP,ZBranch,PIPE1
		DW      DoLIT,DoCREATE,Equals,ZBranch,PIPE1
		DW      RFrom,SWAP,Store,EXIT
PIPE1           DW      DoLIT,-32,THROW

@   skipPARSE   ( char "<chars>ccc<char>" -- c-addr u )
@               Skip leading chars and parse a word using char as a
@               delimeter. Return the name.
@
@   : skipPARSE
@               >R SOURCE >IN @ /STRING    \ c_addr u  R: char
@               DUP IF
@                  BEGIN  OVER C@ R@ =
@                  WHILE  1- SWAP CHAR+ SWAP DUP 0=
@                  UNTIL  R> DROP EXIT
@                  ELSE THEN
@                  DROP SOURCE DROP - 1chars/ >IN ! R> PARSE EXIT
@               THEN R> DROP @

		$COLON  9,'skipPARSE',SkipPARSE,_SLINK
		DW      ToR,SOURCE,ToIN,Fetch,SlashSTRING
		DW      DUPP,ZBranch,SKPAR1
SKPAR2          DW      OVER,CFetch,RFetch,Equals,ZBranch,SKPAR3
		DW      OneMinus,SWAP,CHARPlus,SWAP
		DW      DUPP,ZeroEquals,ZBranch,SKPAR2
		DW      RFrom,DROP,EXIT
SKPAR3          DW      DROP,SOURCE,DROP,Minus,OneCharsSlash
		DW      ToIN,Store,RFrom,PARSE,EXIT
SKPAR1          DW      RFrom,DROP,EXIT

@   rake        ( C: do-sys -- )
@               Gathers LEAVEs.
@
@   : rake      DUP code, rakeVar @
@               BEGIN  2DUP U<
@               WHILE  DUP @ xhere ROT !
@               REPEAT rakeVar ! DROP
@               ?DUP IF                 \ check for ?DO
@                  1 bal+ POSTPONE THEN \ orig type is 1
@               THEN bal- @ COMPILE-ONLY

		$COLON  COMPO+4,'rake',rake,_SLINK
		DW      DUPP,CodeComma,RakeVar,Fetch
RAKE1           DW      TwoDUP,ULess,ZBranch,RAKE2
		DW      DUPP,Fetch,XHere,ROT,Store,Branch,RAKE1
RAKE2           DW      RakeVar,Store,DROP
		DW      QuestionDUP,ZBranch,RAKE3
		DW      One,BalPlus,THENN
RAKE3           DW      BalMinus,EXIT

@   rp0         ( -- a-addr )
@               Pointer to bottom of the return stack.
@
@   : rp0       userP @ CELL+ CELL+ @ @

@               $COLON  3,'rp0',RPZero,_SLINK
@               DW      UserP,Fetch,CELLPlus,CELLPlus,Fetch,EXIT

		$CODE   3,'rp0',RPZero,_SLINK
		pushD   tos
		ldr     r0,=AddrUserP
		ldr     r1,[r0]
		add     r1,r1,#(CELLL*2)
		ldr     tos,[r1]
		$NEXT

@   search-word ( c-addr u -- c-addr u 0 | xt f 1 | xt f -1)
@               Search dictionary for a match with the given name. Return
@               execution token, not-compile-only flag and -1 or 1
@               ( IMMEDIATE) if found@ c-addr u 0 if not.
@
@   : search-word
@               #order @ DUP                    \ not found if #order is 0
@               IF 0
@                  DO 2DUP                      \ ca u ca u
@                     I CELLS #order CELL+ + @  \ ca u ca u wid
@                     (search-wordlist)         \ ca u@ 0 | w f 1 | w f -1
@                     ?DUP IF                   \ ca u@ 0 | w f 1 | w f -1
@                        >R 2SWAP 2DROP R> UNLOOP EXIT \ xt f 1 | xt f -1
@                     THEN                      \ ca u
@                  LOOP 0                       \ ca u 0
@               THEN @

		$COLON  11,'search-word',Search_word,_SLINK
		DW      NumberOrder,Fetch,DUPP,ZBranch,SEARCH1
		DW      Zero,DoDO
SEARCH2         DW      TwoDUP,I,CELLS,NumberOrder,CELLPlus,Plus,Fetch
		DW      ParenSearch_Wordlist,QuestionDUP,ZBranch,SEARCH3
		DW      ToR,TwoSWAP,TwoDROP,RFrom,UNLOOP,EXIT
SEARCH3         DW      DoLOOP,SEARCH2
		DW      Zero
SEARCH1         DW      EXIT

@   sourceVar   ( -- a-addr )
@               Hold the current count and address of the terminal input buffer.

		$VAR   9,'sourceVar',SourceVar,_SLINK
_VAR            SETA _VAR +CELLL

@   sp0         ( -- a-addr )
@               Pointer to bottom of the data stack.
@
@   : sp0       userP @ CELL+ @ @

@               $COLON  3,'sp0',SPZero,_SLINK
@               DW      UserP,Fetch,CELLPlus,Fetch,EXIT

		$CODE   3,'sp0',SPZero,_SLINK
		pushD   tos
		ldr     r0,=AddrUserP
		ldr     r1,[r0]
		add     r1,r1,#CELLL
		ldr     tos,[r1]
		$NEXT

@   TOxhere     ( a-addr -- )
@               Set the next available code space address as a-addr.
@
@   : TOxhere   cpVar ! @

@               $COLON  7,'TOxhere',TOXHere,_SLINK
@               DW      CPVar,Store,EXIT

		$CODE   7,'TOxhere',TOXHere,_SLINK
		ldr     r0,=LocCPVar
		ldr     r1,[r0]
		str     tos,[r1]
		popD    tos
		$NEXT

@   xhere       ( -- a-addr )
@               Return next available code space address.
@
@   : xhere     cpVar @ @

@               $COLON  5,'xhere',XHere,_SLINK
@               DW      CPVar,Fetch,EXIT

		$CODE   5,'xhere',XHere,_SLINK
		pushD   tos
		ldr     r0,=LocCPVar
		ldr     r1,[r0]
		ldr     tos,[r1]
		$NEXT

@   code,       ( x -- )
@               Reserve one cell in code space and store x in it.
@
@   : code,     xhere DUP CELL+ TOxhere ! @

@               $COLON  5,'code,',CodeComma,_SLINK
@               DW      XHere,DUPP,CELLPlus,TOXHere,Store,EXIT

		$CODE   5,'code,',CodeComma,_SLINK
		ldr     r0,=LocCPVar
		ldr     r1,[r0]
		ldr     r2,[r1]
		str     tos,[r2],#CELLL
		popD    tos
		str     r2,[r1]
		$NEXT

@
@ Words for multitasking
@

@   PAUSE       ( -- )
@               Stop current task and transfer control to the task of which
@               'status' USER variable is stored in 'follower' USER variable
@               of current task.
@
@   : PAUSE     rp@ sp@ stackTop !  follower @ >R @ COMPILE-ONLY

		$COLON  COMPO+5,'PAUSE',PAUSE,_SLINK
		DW      RPFetch,SPFetch,StackTop,Store,Follower,Fetch,ToR,EXIT

@   wake        ( -- )
@               Wake current task.
@
@   : wake      R> userP !      \ userP points 'follower' of current task
@               stackTop @ sp!          \ set data stack
@               rp! @ COMPILE-ONLY      \ set return stack

		$COLON  COMPO+4,'wake',Wake,_SLINK
		DW      RFrom,UserP,Store,StackTop,Fetch,SPStore,RPStore,EXIT

@@@@@@@@@@@@@@@@
@ Essential Standard words - Colon definitions
@@@@@@@@@@@@@@@@

@   #           ( ud1 -- ud2 )                  \ CORE
@               Extract one digit from ud1 and append the digit to
@               pictured numeric output string. ( ud2 = ud1 / BASE )
@
@   : #         0 BASE @ UM/MOD >R BASE @ UM/MOD SWAP
@               9 OVER < [ CHAR A CHAR 9 1 + - ] LITERAL AND +
@               [ CHAR 0 ] LITERAL + HOLD R> @

		$COLON  1,'#',NumberSign,_FLINK
		DW      Zero,BASE,Fetch,UMSlashMOD,ToR,BASE,Fetch,UMSlashMOD
		DW      SWAP,DoLIT,9,OVER,LessThan,DoLIT,'A'-'9'-1,ANDD,Plus
		DW      DoLIT,'0',Plus,HOLD,RFrom,EXIT

@   #>          ( xd -- c-addr u )              \ CORE
@               Prepare the output string to be TYPE'd.
@               ||xhere>WORD/#-work-area|
@
@   : #>        2DROP hld @ xhere size-of-PAD + OVER - 1chars/ @

		$COLON  2,'#>',NumberSignGreater,_FLINK
		DW      TwoDROP,HLD,Fetch,XHere,DoLIT,PADSize*CHARR,Plus
		DW      OVER,Minus,OneCharsSlash,EXIT

@   #S          ( ud -- 0 0 )                   \ CORE
@               Convert ud until all digits are added to the output string.
@
@   : #S        BEGIN # 2DUP OR 0= UNTIL @

		$COLON  2,'#S',NumberSignS,_FLINK
NUMSS1          DW      NumberSign,TwoDUP,ORR
		DW      ZeroEquals,ZBranch,NUMSS1
		DW      EXIT

@   '           ( "<spaces>name" -- xt )        \ CORE
@               Parse a name, find it and return xt.
@
@   : '         (') DROP @

		$COLON  1,"'",Tick,_FLINK
		DW      ParenTick,DROP,EXIT

@   +           ( n1|u1 n2|u2 -- n3|u3 )        \ CORE
@               Add top two items and gives the sum.
@
@   : +         um+ DROP @

@               $COLON  1,'+',Plus,_FLINK
@               DW      UMPlus,DROP,EXIT

		$CODE   1,'+',Plus,_FLINK
		popD    r1
		add     tos,tos,r1
		$NEXT

@   +!          ( n|u a-addr -- )               \ CORE
@               Add n|u to the contents at a-addr.
@
@   : +!        SWAP OVER @ + SWAP ! @

@               $COLON  2,'+!',PlusStore,_FLINK
@               DW      SWAP,OVER,Fetch,Plus
@               DW      SWAP,Store,EXIT

		$CODE   2,'+!',PlusStore,_FLINK
		popD    r0
		ldr     r1,[tos]
		add     r1,r1,r0
		str     r1,[tos]
		popD    tos
		$NEXT

@   ,           ( x -- )                        \ CORE
@               Reserve one cell in RAM or ROM data space and store x in it.
@
@   : ,         HERE ! cell-size hereVar +! @

@               $COLON  1,',',Comma,_FLINK
@               DW      HERE,Store
@               DW      DoLIT,CELLL,HereVar,PlusStore,EXIT

		$CODE   1,',',Comma,_FLINK
		ldr     r0,=LocHereVar
		ldr     r1,[r0] @point to ROM or RAM pointer
		ldr     r2,[r1] @get its value
		str     tos,[r2],#CELLL
		popD    tos
		str     r2,[r1]
		$NEXT

@   -           ( n1|u1 n2|u2 -- n3|u3 )        \ CORE
@               Subtract n2|u2 from n1|u1, giving the difference n3|u3.
@
@   : -         NEGATE + @

@               $COLON  1,'-',Minus,_FLINK
@               DW      NEGATE,Plus,EXIT

		$CODE   1,'-',Minus,_FLINK
		popD    r1
		sub     tos,r1,tos
		$NEXT

@   .           ( n -- )                        \ CORE
@               Display a signed number followed by a space.
@
@   : .         S>D D. @

@               $COLON  1,'.',Dot,_FLINK
@               DW      SToD,DDot,EXIT

		$CODE   1,'.',Dot,_FLINK
		pushD   tos
		mov     r1,#0
		@sign-extend tos into tos to form ms of double
		add     tos,r1,tos,asr #32
		b       DDot

@   /           ( n1 n2 -- n3 )                 \ CORE
@               Divide n1 by n2, giving single-cell quotient n3.
@
@   : /         /MOD NIP @

		$COLON  1,'/',Slash,_FLINK
		DW      SlashMOD,NIP,EXIT

@   /MOD        ( n1 n2 -- n3 n4 )              \ CORE
@               Divide n1 by n2, giving single-cell remainder n3 and
@               single-cell quotient n4.
@
@   : /MOD      >R S>D R> FM/MOD @

		$COLON  4,'/MOD',SlashMOD,_FLINK
		DW      ToR,SToD,RFrom,FMSlashMOD,EXIT

@   /STRING     ( c-addr1 u1 n -- c-addr2 u2 )  \ STRING
@               Adjust the char string at c-addr1 by n chars.
@
@   : /STRING   DUP >R - SWAP R> CHARS + SWAP @

@               $COLON  7,'/STRING',SlashSTRING,_FLINK
@               DW      DUPP,ToR,Minus,SWAP,RFrom,CHARS,Plus,SWAP,EXIT

		$CODE   7,'/STRING',SlashSTRING,_FLINK
		popD    r0              @u1 (tos is n)
		popD    r1              @c-addr1
		add     r1,r1,tos
		pushD   r1              @c-addr2 <= c-addr1 + n
		sub     tos,r0,tos      @new count u2 <= u1 - n
		$NEXT

@   1+          ( n1|u1 -- n2|u2 )              \ CORE
@               Increase top of the stack item by 1.
@
@   : 1+        1 + @

@               $COLON  2,'1+',OnePlus,_FLINK
@               DW      One,Plus,EXIT

		$CODE   2,'1+',OnePlus,_FLINK
		add     tos,tos,#1
		$NEXT

@   1-          ( n1|u1 -- n2|u2 )              \ CORE
@               Decrease top of the stack item by 1.
@
@   : 1-        -1 + @

@               $COLON  2,'1-',OneMinus,_FLINK
@               DW      MinusOne,Plus,EXIT

		$CODE   2,'1-',OneMinus,_FLINK
		sub     tos,tos,#1
		$NEXT

@   2!          ( x1 x2 a-addr -- )             \ CORE
@               Store the cell pare x1 x2 at a-addr, with x2 at a-addr and
@               x1 at the next consecutive cell.
@
@   : 2!        SWAP OVER ! CELL+ ! @

@               $COLON  2,'2!',TwoStore,_FLINK
@               DW      SWAP,OVER,Store,CELLPlus,Store,EXIT

		$CODE   2,'2!',TwoStore,_FLINK
		popD    r0
		popD    r1
		str     r0, [tos], #CELLL
		str     r1, [tos]
		popD    tos
		$NEXT

@   2@          ( a-addr -- x1 x2 )             \ CORE
@               Fetch the cell pair stored at a-addr. x2 is stored at a-addr
@               and x1 at the next consecutive cell.
@
@   : 2@        DUP CELL+ @ SWAP @ @

@               $COLON  2,'2@',TwoFetch,_FLINK
@               DW      DUPP,CELLPlus,Fetch,SWAP,Fetch,EXIT

		$CODE   2,'2@',TwoFetch,_FLINK
		ldr     r0, [tos], #4   @x2
		ldr     r1, [tos]
		pushD   r1
		mov     tos, r0
		$NEXT

@   2DROP       ( x1 x2 -- )                    \ CORE
@               Drop cell pair x1 x2 from the stack.

@               $COLON  5,'2DROP',TwoDROP,_FLINK
@               DW      DROP,DROP,EXIT

		$CODE  5,'2DROP',TwoDROP,_FLINK
		popD    tos     @TODO could do this in 1 op..
		popD    tos
		$NEXT

@   2DUP        ( x1 x2 -- x1 x2 x1 x2 )        \ CORE
@               Duplicate cell pair x1 x2.

@               $COLON  4,'2DUP',TwoDUP,_FLINK
@               DW      OVER,OVER,EXIT

		$CODE   4,'2DUP',TwoDUP,_FLINK
		popD    r0      @TODO could save 1 op here..
		pushD   r0
		pushD   tos
		pushD   r0
		$NEXT

@   2SWAP       ( x1 x2 x3 x4 -- x3 x4 x1 x2 )  \ CORE
@               Exchange the top two cell pairs.
@
@   : 2SWAP     ROT >R ROT R> @

@               $COLON  5,'2SWAP',TwoSWAP,_FLINK
@               DW      ROT,ToR,ROT,RFrom,EXIT

		$CODE   5,'2SWAP',TwoSWAP,_FLINK
		popD    r0              @x3
		popD    r1              @x2
		popD    r2              @x1
		pushD   r0
		pushD   tos
		pushD   r2
		mov     tos,r1
		$NEXT

@   :           ( "<spaces>name" -- colon-sys ) \ CORE
@               Start a new colon definition using next word as its name.
@
@   : :         :NONAME ROT head,  -1 TO notNONAME? @

		$COLON  1,':',COLON,_FLINK
		DW      ColonNONAME,ROT,HeadComma
		DW      DoLIT,-1,DoTO,AddrNotNONAMEQ,EXIT

@   :NONAME     ( -- xt colon-sys )             \ CORE EXT
@               Create an execution token xt, enter compilation state and
@               start the current definition.
@
@   : :NONAME   bal IF -29 THROW THEN           \ compiler nesting
@               ['] doLIST xt, DUP -1
@               0 TO notNONAME?  1 TO bal  ] @

		$COLON  7,':NONAME',ColonNONAME,_FLINK
		DW      Bal,ZBranch,NONAME1
		DW      DoLIT,-29,THROW
NONAME1         DW      DoLIT,DoLIST,xtComma,DUPP,DoLIT,-1
		DW      Zero,DoTO,AddrNotNONAMEQ
		DW      One,DoTO,AddrBal,RightBracket,EXIT

@   @           ( colon-sys -- )                \ CORE
@               Terminate a colon definition.
@
@   : @         bal 1- IF -22 THROW THEN        \ control structure mismatch
@               NIP 1+ IF -22 THROW THEN        \ colon-sys type is -1
@               notNONAME? IF   \ if the last definition is not created by ':'
@                 linkLast  0 TO notNONAME?     \ link the word to wordlist
@               THEN  POSTPONE EXIT     \ add EXIT at the end of the definition
@               0 TO bal  POSTPONE [ @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+1,'@',Semicolon,_FLINK
		DW      Bal,OneMinus,ZBranch,SEMI1
		DW      DoLIT,-22,THROW
SEMI1           DW      NIP,OnePlus,ZBranch,SEMI2
		DW      DoLIT,-22,THROW
SEMI2           DW      NotNONAMEQ,ZBranch,SEMI3
		DW      LinkLast,Zero,DoTO,AddrNotNONAMEQ
SEMI3           DW      DoLIT,EXIT,COMPILEComma
		DW      Zero,DoTO,AddrBal,LeftBracket,EXIT

@   <           ( n1 n2 -- flag )               \ CORE
@               Returns true if n1 is less than n2.
@
@   : <         2DUP XOR 0<             \ same sign?
@               IF DROP 0< EXIT THEN    \ different signs, true if n1 <0
@               - 0< @                  \ same signs, true if n1-n2 <0

		$COLON  1,'<',LessThan,_FLINK
		DW      TwoDUP,XORR,ZeroLess,ZBranch,LESS1
		DW      DROP,ZeroLess,EXIT
LESS1           DW      Minus,ZeroLess,EXIT

@   <#          ( -- )                          \ CORE
@               Initiate the numeric output conversion process.
@               ||xhere>WORD/#-work-area|
@
@   : <#        xhere size-of-PAD + hld ! @

@		$COLON  2,'<#',LessNumberSign,_FLINK
@		DW      XHere,DoLIT,PADSize*CHARR,Plus,HLD,Store,EXIT

		$CODE   2,'<#',LessNumberSign,_FLINK
		ldr     r0,=LocCPVar
		ldr     r1,[r0]
		ldr     r2,[r1] @xhere address
		add     r2,r2,#(PADSize*CHARR)
		ldr     r3,=LocHLD
		str     r2,[r3]
		$NEXT

@   =           ( x1 x2 -- flag )               \ CORE
@               Return true if top two are equal.
@
@   : =         XORR 0= @

@               $COLON  1,'=',Equals,_FLINK
@               DW      XORR,ZeroEquals,EXIT

		$CODE   1,'=',Equals,_FLINK
		popD    r0
		subs    tos,tos,r0      @if equal tos will be 0 (FALSE)
		ldreq   tos,=TRUEE
		ldrne   tos,=FALSEE
		$NEXT

@   >           ( n1 n2 -- flag )               \ CORE
@               Returns true if n1 is greater than n2.
@
@   : >         SWAP < @

		$COLON  1,'>',GreaterThan,_FLINK
		DW      SWAP,LessThan,EXIT

@   >IN         ( -- a-addr )
@               Hold the character pointer while parsing input stream.

		$VAR    3,'>IN',ToIN,_FLINK

@   >NUMBER     ( ud1 c-addr1 u1 -- ud2 c-addr2 u2 )    \ CORE
@               Add number string's value to ud1. Leaves string of any
@               unconverted chars.
@
@   : >NUMBER   BEGIN  DUP
@               WHILE  >R  DUP >R C@                    \ ud char  R: u c-addr
@                      DUP [ CHAR 9 1+ ] LITERAL [CHAR] A WITHIN
@                          IF DROP R> R> EXIT THEN
@                      [ CHAR 0 ] LITERAL - 9 OVER <
@                      [ CHAR A CHAR 9 1 + - ] LITERAL AND -
@                      DUP 0 BASE @ WITHIN
@               WHILE  SWAP BASE @ UM* DROP ROT BASE @ UM* D+ R> R> 1 /STRING
@               REPEAT DROP R> R>
@               THEN @

		$COLON  7,'>NUMBER',ToNUMBER,_FLINK
TONUM1          DW      DUPP,ZBranch,TONUM3
		DW      ToR,DUPP,ToR,CFetch,DUPP
		DW      DoLIT,'9'+1,DoLIT,'A',WITHIN,ZeroEquals,ZBranch,TONUM2
		DW      DoLIT,'0',Minus,DoLIT,9,OVER,LessThan
		DW      DoLIT,'A'-'9'-1,ANDD,Minus,DUPP
		DW      Zero,BASE,Fetch,WITHIN,ZBranch,TONUM2
		DW      SWAP,BASE,Fetch,UMStar,DROP,ROT,BASE,Fetch
		DW      UMStar,DPlus,RFrom,RFrom,One,SlashSTRING
		DW      Branch,TONUM1
TONUM2          DW      DROP,RFrom,RFrom
TONUM3          DW      EXIT

@   ?DUP        ( x -- x x | 0 )                \ CORE
@               Duplicate top of the stack if it is not zero.
@
@   : ?DUP      DUP IF DUP THEN @

@               $COLON  4,'?DUP',QuestionDUP,_FLINK
@               DW      DUPP,ZBranch,QDUP1
@               DW      DUPP
@QDUP1          DW      EXIT

		$CODE   4,'?DUP',QuestionDUP,_FLINK
		orrs    tos,tos,#0              @set flags
		strne   tos, [dsp, # - CELLL]!  @pushD if ne
		$NEXT

@   ABORT       ( i*x -- ) ( R: j*x -- )        \ EXCEPTION EXT
@               Reset data stack and jump to QUIT.
@
@   : ABORT     -1 THROW @

@               $COLON  5,'ABORT',ABORT,_FLINK
@               DW      MinusOne,THROW

		$CODE   5,'ABORT',ABORT,_FLINK
		pushD   tos			@gonna trash the stack so no need..
		mov     tos,#-1
		b       THROW

@NAC mods for handshaking: FLOW-ON at start, FLOW-OFF at end and use EMITE for
@all output in between.
@   ACCEPT      ( c-addr +n1 -- +n2 )           \ CORE
@               Accept a string of up to +n1 chars. Return with actual count.
@               Implementation-defined editing. Stops at EOL# .
@               Supports backspace and delete editing.
@
@   : ACCEPT    FLOW-ON >R 0
@               BEGIN  DUP R@ <                 \ ca n2 f  R: n1
@               WHILE  EKEY max-char AND
@                      DUP BL <
@                      IF   DUP  cr# = IF ROT 2DROP R> DROP FLOW-OFF EXIT THEN
@                           DUP  tab# =
@                           IF   DROP 2DUP + BL DUP EMITE SWAP C! 1+
@                           ELSE DUP  bsp# =
@                                SWAP del# = OR
@                                IF DROP DUP
@                                       \ discard the last char if not 1st char
@                                IF 1- bsp# EMITE BL EMITE bsp# EMITE THEN THEN
@                           THEN
@                      ELSE >R 2DUP CHARS + R> DUP EMITE SWAP C! 1+  THEN
@                      THEN
@               REPEAT SWAP  R> 2DROP FLOW-OFF @

		$COLON  6,'ACCEPT',ACCEPT,_FLINK
		DW      FLOW_ON,ToR,Zero
ACCPT1          DW      DUPP,RFetch,LessThan,ZBranch,ACCPT5
		DW      EKEY,DoLIT,MaxChar,ANDD
		DW      DUPP,BLank,LessThan,ZBranch,ACCPT3
		DW      DUPP,DoLIT,CRR,Equals,ZBranch,ACCPT4
		DW      ROT,TwoDROP,RFrom,DROP,FLOW_OFF,EXIT
ACCPT4          DW      DUPP,DoLIT,TABB,Equals,ZBranch,ACCPT6
		DW      DROP,TwoDUP,Plus,BLank,DUPP,EMITE,SWAP,CStore,OnePlus
		DW      Branch,ACCPT1
ACCPT6          DW      DUPP,DoLIT,BKSPP,Equals
		DW      SWAP,DoLIT,DEL,Equals,ORR,ZBranch,ACCPT1
		DW      DUPP,ZBranch,ACCPT1
		DW      OneMinus,DoLIT,BKSPP,EMITE,BLank,EMITE,DoLIT,BKSPP,EMITE
		DW      Branch,ACCPT1
ACCPT3          DW      ToR,TwoDUP,CHARS,Plus,RFrom,DUPP,EMITE,SWAP,CStore
		DW      OnePlus,Branch,ACCPT1
ACCPT5          DW      SWAP,RFrom,TwoDROP,FLOW_OFF,EXIT

@   AGAIN       ( C: dest -- )                  \ CORE EXT
@               Resolve backward reference dest. Typically used as
@               BEGIN ... AGAIN . Move control to the location specified by
@               dest on execution.
@
@   : AGAIN     IF -22 THROW THEN  \ control structure mismatch@ dest type is 0
@               POSTPONE branch code, bal- @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'AGAIN',AGAIN,_FLINK
		DW      ZBranch,AGAIN1
		DW      DoLIT,-22,THROW
AGAIN1          DW      DoLIT,Branch,COMPILEComma,CodeComma,BalMinus,EXIT

@   AHEAD       ( C: -- orig )                  \ TOOLS EXT
@               Put the location of a new unresolved forward reference onto
@               control-flow stack.
@
@   : AHEAD     POSTPONE branch xhere 0 code,
@               1 bal+          \ orig type is 1
@               @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'AHEAD',AHEAD,_FLINK
		DW      DoLIT,Branch,COMPILEComma,XHere,Zero,CodeComma
		DW      One,BalPlus,EXIT

@NAC: this was processed incorrectly by makesrc - fixed by defining SPC
@instead of using ' '
@   BL          ( -- char )                     \ CORE
@               Return the value of the blank character.
@
@   : BL        blank-char-value EXIT @

		$CONST  2,'BL',BLank,SPC,_FLINK

@   CATCH       ( i*x xt -- j*x 0 | i*x n )     \ EXCEPTION
@               Push an exception frame on the exception stack and then execute
@               the execution token xt in such a way that control can be
@               transferred to a point just after CATCH if THROW is executed
@               during the execution of xt.
@
@   : CATCH     sp@ >R throwFrame @ >R          \ save error frame
@               rp@ throwFrame !  EXECUTE       \ execute
@               R> throwFrame !                 \ restore error frame
@               R> DROP  0 @                    \ no error

		$COLON  5,'CATCH',CATCH,_FLINK
		DW      SPFetch,ToR,ThrowFrame,Fetch,ToR
		DW      RPFetch,ThrowFrame,Store,EXECUTE
		DW      RFrom,ThrowFrame,Store
		DW      RFrom,DROP,Zero,EXIT

@   CELL+       ( a-addr1 -- a-addr2 )          \ CORE
@               Return next aligned cell address.
@
@   : CELL+     cell-size + @

@               $COLON  5,'CELL+',CELLPlus,_FLINK
@               DW      DoLIT,CELLL,Plus,EXIT

		$CODE   5,'CELL+',CELLPlus,_FLINK
		add     tos, tos, #CELLL
		$NEXT

@   CHAR+       ( c-addr1 -- c-addr2 )          \ CORE
@               Returns next character-aligned address.
@
@   : CHAR+     char-size + @

@               $COLON  5,'CHAR+',CHARPlus,_FLINK
@               DW      DoLIT,CHARR,Plus,EXIT

		$CODE   5,'CHAR+',CHARPlus,_FLINK
		add     tos, tos, #CHARR
		$NEXT

@   COMPILE,    ( xt -- )                       \ CORE EXT
@               Compile the execution token on data stack into current
@               colon definition.
@
@   : COMPILE,  code, @ COMPILE-ONLY

@               $COLON  COMPO+8,'COMPILE,',COMPILEComma,_FLINK
@               DW      CodeComma,EXIT

		$CODE   COMPO+8,'COMPILE,',COMPILEComma,_FLINK
		b       CodeComma

@   CONSTANT    ( x "<spaces>name" -- )         \ CORE
@               name Execution: ( -- x )
@               Create a definition for name which pushes x on the stack on
@               execution.
@
@   : CONSTANT  bal IF -29 THROW THEN           \ compiler nesting
@               ['] doCONST xt, head, code, linkLast @

		$COLON  8,'CONSTANT',CONSTANT,_FLINK
		DW      Bal,ZBranch,CONST1
		DW      DoLIT,-29,THROW
CONST1          DW      DoLIT,DoCONST,xtComma,HeadComma,CodeComma,LinkLast,EXIT

@   COUNT       ( c-addr1 -- c-addr2 u )        \ CORE
@               Convert counted string to string specification. c-addr2 is
@               the next char-aligned address after c-addr1 and u is the
@               contents at c-addr1.
@
@   : COUNT     DUP CHAR+ SWAP C@ @

@               $COLON  5,'COUNT',COUNT,_FLINK
@               DW      DUPP,CHARPlus,SWAP,CFetch,EXIT

		$CODE   5,'COUNT',COUNT,_FLINK
		ldrb    r0,[tos]        @u
		add     tos,tos,#1
		pushD   tos
		mov     tos,r0
		$NEXT

@   CREATE      ( "<spaces>name" -- )           \ CORE
@               name Execution: ( -- a-addr )
@               Create a data object in RAM/ROM data space, which return
@               data object address on execution
@
@   : CREATE    bal IF -29 THROW THEN           \ compiler nesting
@               ['] doCREATE xt, head,
@               xhere DUP CELL+ CELL+ TOxhere   \ reserve two cells
@               0 OVER !                \ no DOES> code yet
@               ALIGN HERE SWAP CELL+ ! \ >BODY returns this address
@               linkLast @              \ link CREATEd word to current wordlist

		$COLON  6,'CREATE',CREATE,_FLINK
		DW      Bal,ZBranch,CREAT1
		DW      DoLIT,-29,THROW
CREAT1          DW      DoLIT,DoCREATE,xtComma,HeadComma
		DW      XHere,DUPP,CELLPlus,CELLPlus,TOXHere
		DW      Zero,OVER,Store
		DW      ALIGNN,HERE,SWAP,CELLPlus,Store
		DW      LinkLast,EXIT

@   D+          ( d1|ud1 d2|ud2 -- d3|ud3 )     \ DOUBLE
@               Add double-cell numbers.
@
@   : D+        >R SWAP >R um+ R> R> + + @

@               $COLON  2,'D+',DPlus,_FLINK
@               DW      ToR,SWAP,ToR,UMPlus
@               DW      RFrom,RFrom,Plus,Plus,EXIT

		$CODE   2,'D+',DPlus,_FLINK
		popD    r0      @d2L (tos is d2H)
		popD    r1      @d1H
		popD    r2      @d1L
		adds    r3,r0,r2
		pushD   r3
		adc     tos,tos,r1
		$NEXT

@   D.          ( d -- )                        \ DOUBLE
@               Display d in free field format followed by a space.
@
@   : D.        (d.) TYPE SPACE @

		$COLON  2,'D.',DDot,_FLINK
		DW      ParenDDot,TYPEE,SPACE,EXIT

@   DECIMAL     ( -- )                          \ CORE
@               Set the numeric conversion radix to decimal 10.
@
@   : DECIMAL   10 BASE ! @

@               $COLON  7,'DECIMAL',DECIMAL,_FLINK
@               DW      DoLIT,10,BASE,Store,EXIT

		$CODE   7,'DECIMAL',DECIMAL,_FLINK
		ldr     r0,=LocBASE
		mov     r1,#10
		str     r1,[r0]
		$NEXT

@   DEPTH       ( -- +n )                       \ CORE
@               Return the depth of the data stack.
@
@   : DEPTH     sp@ sp0 SWAP - cell-size / @

		$COLON  5,'DEPTH',DEPTH,_FLINK
		DW      SPFetch,SPZero,SWAP,Minus
		DW      DoLIT,CELLL,Slash,EXIT

@   DNEGATE     ( d1 -- d2 )                    \ DOUBLE
@               Two's complement of double-cell number.
@
@   : DNEGATE   INVERT >R INVERT 1 um+ R> + @

@               $COLON  7,'DNEGATE',DNEGATE,_FLINK
@               DW      INVERT,ToR,INVERT
@               DW      One,UMPlus
@               DW      RFrom,Plus,EXIT

		$CODE   7,'DNEGATE',DNEGATE,_FLINK
		popD    r0
		mvn     tos,tos @1's complement of high part
		mvn     r0,r0   @1's complement of lo part
		adds    r0,r0,#1
		adc     tos,tos,#0
		pushD   r0
		$NEXT

@   EKEY        ( -- u )                        \ FACILITY EXT
@               Receive one keyboard event u.
@
@   : EKEY      BEGIN PAUSE EKEY? UNTIL 'ekey EXECUTE @

		$COLON  4,'EKEY',EKEY,_FLINK
EKEY1           DW      PAUSE,EKEYQuestion,ZBranch,EKEY1
		DW      TickEKEY,EXECUTE,EXIT

@   EMIT        ( x -- )                        \ CORE
@               Send a character to the output device.
@
@   : EMIT      'emit EXECUTE @

@               $COLON  4,'EMIT',EMIT,_FLINK
@               DW      TickEMIT,EXECUTE,EXIT

		$CODE   4,'EMIT',EMIT,_FLINK
EMIT01          ldr     r0,=AddrTEMIT
		ldr     r1,[r0]
		mov     pc,r1

@NAC added for file handshake. TODO should it be slink instead?
@   EMITE       ( x -- )
@               Send a character to the output device unless FILE bit
@               is set in IOBYTES
@
@   : EMITE     IOBYTES 10000000 AND 
@               IF 'emit EXECUTE THEN DROP @

@TODO test that high-level definition

		$CODE   5,'EMITE',EMITE,_FLINK
		ldr     r0,=AddrIOBYTES         @find out whether to emit it
		ldr     r1,[r0]
		ands    r1,r1,#&10000000
		beq     EMIT01                  @yes, do it
		popD    tos
		$NEXT

@   FM/MOD      ( d n1 -- n2 n3 )               \ CORE
@               Signed floored divide of double by single. Return mod n2
@               and quotient n3.
@
@   : FM/MOD    DUP >R 2DUP XOR >R >R DUP 0< IF DNEGATE THEN
@               R@ ABS UM/MOD
@               R> 0< IF SWAP NEGATE SWAP THEN
@               R> 0< IF NEGATE         \ negative quotient
@                   OVER IF R@ ROT - SWAP 1- THEN
@                   R> DROP
@                   0 OVER < IF -11 THROW THEN          \ result out of range
@                   EXIT                        THEN
@               R> DROP  DUP 0< IF -11 THROW THEN @     \ result out of range

		$COLON  6,'FM/MOD',FMSlashMOD,_FLINK
		DW      DUPP,ToR,TwoDUP,XORR,ToR,ToR,DUPP,ZeroLess
		DW      ZBranch,FMMOD1
		DW      DNEGATE
FMMOD1          DW      RFetch,ABSS,UMSlashMOD
		DW      RFrom,ZeroLess,ZBranch,FMMOD2
		DW      SWAP,NEGATE,SWAP
FMMOD2          DW      RFrom,ZeroLess,ZBranch,FMMOD3
		DW      NEGATE,OVER,ZBranch,FMMOD4
		DW      RFetch,ROT,Minus,SWAP,OneMinus
FMMOD4          DW      RFrom,DROP
		DW      DoLIT,0,OVER,LessThan,ZBranch,FMMOD6
		DW      DoLIT,-11,THROW
FMMOD6          DW      EXIT
FMMOD3          DW      RFrom,DROP,DUPP,ZeroLess,ZBranch,FMMOD6
		DW      DoLIT,-11,THROW

@   GET-CURRENT   ( -- wid )                    \ SEARCH
@               Return the indentifier of the compilation wordlist.
@
@   : GET-CURRENT   current @ @

		$COLON  11,'GET-CURRENT',GET_CURRENT,_FLINK
		DW      Current,Fetch,EXIT

@   HERE        ( -- addr )                     \ CORE
@               Return data space pointer.
@
@   : HERE      hereVar @ @

@               $COLON  4,'HERE',HERE,_FLINK
@               DW      HereVar,Fetch,EXIT

		$CODE   4,'HERE',HERE,_FLINK
		pushD   tos
		ldr     r0,=LocHereVar
		ldr     r1,[r0] @point to ROM or RAM pointer
		ldr     tos,[r1] @get its value
		$NEXT

@   HOLD        ( char -- )                     \ CORE
@               Add char to the beginning of pictured numeric output string.
@
@   : HOLD      hld @  1 CHARS - DUP hld ! C! @

@               $COLON  4,'HOLD',HOLD,_FLINK
@               DW      HLD,Fetch,DoLIT,0-CHARR,Plus
@               DW      DUPP,HLD,Store,CStore,EXIT

		$CODE   4,'HOLD',HOLD,_FLINK
		ldr     r0,=LocHLD
		ldr     r1,[r0]
		sub     r1,r1,#CHARR
		strb    tos,[r1]
		str     r1,[r0]
		popD    tos
		$NEXT

@   I           ( -- n|u ) ( R: loop-sys -- loop-sys )  \ CORE
@               Push the innermost loop index.
@
@   : I         rp@ [ 1 CELLS ] LITERAL + @
@               rp@ [ 2 CELLS ] LITERAL + @  +  @ COMPILE-ONLY

@               $COLON  COMPO+1,'I',I,_FLINK
@               DW      RPFetch,DoLIT,CELLL,Plus,Fetch
@               DW      RPFetch,DoLIT,2*CELLL,Plus,Fetch,Plus,EXIT

		$CODE   COMPO+1,'I',I,_FLINK
		pushD   tos
		ldr     r0,[rsp] @ note we're one CELLL closer to the tos in CODE
		ldr     tos,[rsp, #CELLL]
		add     tos,tos,r0
		$NEXT

@   IF          Compilation: ( C: -- orig )             \ CORE
@               Run-time: ( x -- )
@               Put the location of a new unresolved forward reference orig
@               onto the control flow stack. On execution jump to location
@               specified by the resolution of orig if x is zero.
@
@   : IF        POSTPONE 0branch xhere 0 code,
@               1 bal+          \ orig type is 1
@               @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+2,'IF',IFF,_FLINK
		DW      DoLIT,ZBranch,COMPILEComma,XHere,Zero,CodeComma
		DW      One,BalPlus,EXIT

@   INVERT      ( x1 -- x2 )                    \ CORE
@               Return one's complement of x1.
@
@   : INVERT    -1 XOR @

@               $COLON  6,'INVERT',INVERT,_FLINK
@               DW      MinusOne,XORR,EXIT

		$CODE   6,'INVERT',INVERT,_FLINK
		mvn     tos,tos
		$NEXT

@   KEY         ( -- char )                     \ CORE
@               Receive a character. Do not display char.
@
@   : KEY       EKEY max-char AND @

		$COLON  3,'KEY',KEY,_FLINK
		DW      EKEY,DoLIT,MaxChar,ANDD,EXIT

@   LITERAL     Compilation: ( x -- )           \ CORE
@               Run-time: ( -- x )
@               Append following run-time semantics. Put x on the stack on
@               execution
@
@   : LITERAL   POSTPONE doLIT code, @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+7,'LITERAL',LITERAL,_FLINK
		DW      DoLIT,DoLIT,COMPILEComma,CodeComma,EXIT

@   NEGATE      ( n1 -- n2 )                    \ CORE
@               Return two's complement of n1.
@
@   : NEGATE    INVERT 1+ @

@               $COLON  6,'NEGATE',NEGATE,_FLINK
@               DW      INVERT,OnePlus,EXIT

		$CODE   6,'NEGATE',NEGATE,_FLINK
		mvn     tos,tos
		add     tos,tos,#1
		$NEXT

@   NIP         ( n1 n2 -- n2 )                 \ CORE EXT
@               Discard the second stack item.
@
@   : NIP       SWAP DROP @

@               $COLON  3,'NIP',NIP,_FLINK
@               DW      SWAP,DROP,EXIT

		$CODE   3,'NIP',NIP,_FLINK
		popD    r0
		$NEXT

		LTORG

@   PARSE       ( char "ccc<char>"-- c-addr u )         \ CORE EXT
@               Scan input stream and return counted string delimited by char.
@
@   : PARSE     >R  SOURCE >IN @ /STRING        \ c-addr u  R: char
@               DUP IF
@                  OVER CHARS + OVER       \ c-addr c-addr+u c-addr  R: char
@                  BEGIN  DUP C@ R@ XOR
@                  WHILE  CHAR+ 2DUP =
@                  UNTIL  DROP OVER - 1chars/ DUP
@                  ELSE   NIP  OVER - 1chars/ DUP CHAR+
@                  THEN   >IN +!
@               THEN   R> DROP EXIT @

		$COLON  5,'PARSE',PARSE,_FLINK
		DW      ToR,SOURCE,ToIN,Fetch,SlashSTRING
		DW      DUPP,ZBranch,PARSE4
		DW      OVER,CHARS,Plus,OVER
PARSE1          DW      DUPP,CFetch,RFetch,XORR,ZBranch,PARSE3
		DW      CHARPlus,TwoDUP,Equals,ZBranch,PARSE1
PARSE2          DW      DROP,OVER,Minus,DUPP,OneCharsSlash,Branch,PARSE5
PARSE3          DW      NIP,OVER,Minus,DUPP,OneCharsSlash,CHARPlus
PARSE5          DW      ToIN,PlusStore
PARSE4          DW      RFrom,DROP,EXIT

@   QUIT        ( -- ) ( R: i*x -- )            \ CORE
@               Empty the return stack, store zero in SOURCE-ID, make the user
@               input device the input source, and start text interpreter.
@
@   : QUIT      BEGIN
@                 rp0 rp!  0 TO SOURCE-ID  0 TO bal  POSTPONE [
@                 BEGIN CR REFILL DROP SPACE    \ REFILL returns always true
@                       ['] interpret CATCH ?DUP 0=
@                 WHILE STATE @ 0= IF .prompt THEN
@                 REPEAT
@                 DUP -1 XOR IF                                 \ ABORT
@                 DUP -2 = IF SPACE abort"msg 2@ TYPE    ELSE   \ ABORT"
@                 SPACE errWord 2@ TYPE
@                 SPACE [CHAR] ? EMIT SPACE
@                 DUP -1 -58 WITHIN IF ." Exception # " . ELSE \ undefined exception
@                 CELLS THROWMsgTbl + @ COUNT TYPE       THEN THEN THEN
@                 sp0 sp!
@               AGAIN @

		$COLON  4,'QUIT',QUIT,_FLINK
QUIT1           DW      RPZero,RPStore,Zero,DoTO,AddrSOURCE_ID
		DW      Zero,DoTO,AddrBal,LeftBracket
QUIT2           DW      CR,REFILL,DROP,SPACE
		DW      DoLIT,Interpret,CATCH,QuestionDUP,ZeroEquals
		DW      ZBranch,QUIT3
		DW      STATE,Fetch,ZeroEquals,ZBranch,QUIT2
		DW      DotPrompt,Branch,QUIT2
QUIT3           DW      DUPP,MinusOne,XORR,ZBranch,QUIT5
		DW      DUPP,DoLIT,-2,Equals,ZBranch,QUIT4
		DW      SPACE,AbortQMsg,TwoFetch,TYPEE,Branch,QUIT5
QUIT4           DW      SPACE,ErrWord,TwoFetch,TYPEE
		DW      SPACE,DoLIT,'?',EMIT,SPACE
		DW      DUPP,MinusOne,DoLIT,-58,WITHIN,ZBranch,QUIT7
		$INSTR  ' Exception # '
		DW      TYPEE,Dot,Branch,QUIT5
QUIT7           DW      CELLS,THROWMsgTbl,Plus,Fetch,COUNT,TYPEE
QUIT5           DW      SPZero,SPStore,Branch,QUIT1

@   REFILL      ( -- flag )                     \ CORE EXT
@               Attempt to fill the input buffer from the input source. Make
@               the result the input buffer, set >IN to zero, and return true
@               if successful. Return false if the input source is a string
@               from EVALUATE.
@
@   : REFILL    SOURCE-ID IF 0 EXIT THEN
@               npVar @ [ size-of-PAD CHARS 2* ] LITERAL - DUP
@               size-of-PAD ACCEPT sourceVar 2!
@               0 >IN ! -1 @

		$COLON  6,'REFILL',REFILL,_FLINK
		DW      SOURCE_ID,ZBranch,REFIL1
		DW      Zero,EXIT
REFIL1          DW      NPVar,DoLIT,0-PADSize*CHARR*2,Plus,DUPP
		DW      DoLIT,PADSize*CHARR,ACCEPT,SourceVar,TwoStore
		DW      Zero,ToIN,Store,MinusOne,EXIT

@   ROT         ( x1 x2 x3 -- x2 x3 x1 )        \ CORE
@               Rotate the top three data stack items.
@
@   : ROT       >R SWAP R> SWAP @

@               $COLON  3,'ROT',ROT,_FLINK
@               DW      ToR,SWAP,RFrom,SWAP,EXIT

		$CODE   3,'ROT',ROT,_FLINK
		popD    r0      @x2 (tos=x3)
		popD    r1      @x1
		pushD   r0
		pushD   tos
		mov     tos,r1
		$NEXT

@   S>D         ( n -- d )                      \ CORE
@               Convert a single-cell number n to double-cell number.
@
@   : S>D       DUP 0< @

@               $COLON  3,'S>D',SToD,_FLINK
@               DW      DUPP,ZeroLess,EXIT

		$CODE   3,'S>D',SToD,_FLINK
		pushD   tos
		mov     r1,#0
		@sign-extend tos into tos to form ms of double
		add     tos,r1,tos,asr #32
		$NEXT

@   SEARCH-WORDLIST     ( c-addr u wid -- 0 | xt 1 | xt -1)     \ SEARCH
@               Search word list for a match with the given name.
@               Return execution token and -1 or 1 ( IMMEDIATE) if found.
@               Return 0 if not found.
@
@   : SEARCH-WORDLIST
@               (search-wordlist) DUP IF NIP THEN @

		$COLON  15,'SEARCH-WORDLIST',SEARCH_WORDLIST,_FLINK
		DW      ParenSearch_Wordlist,DUPP,ZBranch,SRCHW1
		DW      NIP
SRCHW1          DW      EXIT

@   SIGN        ( n -- )                        \ CORE
@               Add a minus sign to the numeric output string if n is negative.
@
@   : SIGN      0< IF [CHAR] - HOLD THEN @

		$COLON  4,'SIGN',SIGN,_FLINK
		DW      ZeroLess,ZBranch,SIGN1
		DW      DoLIT,'-',HOLD
SIGN1           DW      EXIT

@   SOURCE      ( -- c-addr u )                 \ CORE
@               Return input buffer string.
@
@   : SOURCE    sourceVar 2@ @

		$COLON  6,'SOURCE',SOURCE,_FLINK
		DW      SourceVar,TwoFetch,EXIT

@   SPACE       ( -- )                          \ CORE
@               Send the blank character to the output device.
@
@   : SPACE     32 EMIT @

@               $COLON  5,'SPACE',SPACE,_FLINK
@               DW      BLank,EMIT,EXIT

		$CODE   5,'SPACE',SPACE,_FLINK
		pushD   tos
		mov     tos,#SPC
		b       EMIT

@   STATE       ( -- a-addr )                   \ CORE
@               Return the address of a cell containing compilation-state flag
@               which is true in compilation state or false otherwise.

		$VAR    5,'STATE',STATE,_FLINK

@   THEN        Compilation: ( C: orig -- )     \ CORE
@               Run-time: ( -- )
@               Resolve the forward reference orig.
@
@   : THEN      1- IF -22 THROW THEN    \ control structure mismatch
@                                       \ orig type is 1
@               xhere SWAP ! bal- @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+4,'THEN',THENN,_FLINK
		DW      OneMinus,ZBranch,THEN1
		DW      DoLIT,-22,THROW
THEN1           DW      XHere,SWAP,Store,BalMinus,EXIT

@   THROW       ( k*x n -- k*x | i*x n )        \ EXCEPTION
@               If n is not zero, pop the topmost exception frame from the
@               exception stack, along with everything on the return stack
@               above the frame. Then restore the condition before CATCH and
@               transfer control just after the CATCH that pushed that
@               exception frame.
@
@   : THROW     ?DUP
@               IF   throwFrame @ rp!   \ restore return stack
@                    R> throwFrame !    \ restore THROW frame
@                    R> SWAP >R sp!     \ restore data stack
@                    DROP R>
@                    'init-i/o EXECUTE
@               THEN @

		$COLON  5,'THROW',THROW,_FLINK
		DW      QuestionDUP,ZBranch,THROW1
		DW      ThrowFrame,Fetch,RPStore,RFrom,ThrowFrame,Store
		DW      RFrom,SWAP,ToR,SPStore,DROP,RFrom
		DW      TickINIT_IO,EXECUTE
THROW1          DW      EXIT

@   TYPE        ( c-addr u -- )                 \ CORE
@               Display the character string if u is greater than zero.
@
@   : TYPE      ?DUP IF 0 DO DUP C@ EMIT CHAR+ LOOP THEN DROP @

		$COLON  4,'TYPE',TYPEE,_FLINK
		DW      QuestionDUP,ZBranch,TYPE2
		DW      Zero,DoDO
TYPE1           DW      DUPP,CFetch,EMIT,CHARPlus,DoLOOP,TYPE1
TYPE2           DW      DROP,EXIT

@   U<          ( u1 u2 -- flag )               \ CORE
@               Unsigned compare of top two items. True if u1 < u2.
@
@   : U<        2DUP XOR 0< IF NIP 0< EXIT THEN - 0< @

@		$COLON  2,'U<',ULess,_FLINK
@		DW      TwoDUP,XORR,ZeroLess
@		DW      ZBranch,ULES1
@		DW      NIP,ZeroLess,EXIT
@ULES1           DW      Minus,ZeroLess,EXIT

		$CODE   2,'U<',ULess,_FLINK
		popD    r0      @u1
		cmp     tos,r0  @u2-u1
		ldr     tos,=TRUEE
		ldrls   tos,=FALSEE @ C or Z
		$NEXT

@   UM*         ( u1 u2 -- ud )                 \ CORE
@               Unsigned multiply. Return double-cell product.
@
@   : UM*       0 SWAP cell-size-in-bits 0 DO
@                  DUP um+ >R >R DUP um+ R> +
@                  R> IF >R OVER um+ R> + THEN     \ if carry
@               LOOP ROT DROP @

@               $COLON  3,'UM*',UMStar,_FLINK
@               DW      Zero,SWAP,DoLIT,CELLL*8,Zero,DoDO
@UMST1          DW      DUPP,UMPlus,ToR,ToR
@               DW      DUPP,UMPlus,RFrom,Plus,RFrom
@               DW      ZBranch,UMST2
@               DW      ToR,OVER,UMPlus,RFrom,Plus
@UMST2          DW      DoLOOP,UMST1
@               DW      ROT,DROP,EXIT

		$CODE   3,'UM*',UMStar,_FLINK
		popD    r0
		umull   r1, tos, r0, tos
		pushD   r1                      @ms 32-bits are at top of stack
		$NEXT

@   UM/MOD      ( ud u1 -- u2 u3 )              \ CORE
@               Unsigned division of a double-cell number ud by a single-cell
@               number u1. Return remainder u2 and quotient u3.
@
@   : UM/MOD    DUP 0= IF -10 THROW THEN        \ divide by zero
@               2DUP U< IF
@                  NEGATE cell-size-in-bits 0
@                  DO   >R DUP um+ >R >R DUP um+ R> + DUP
@                       R> R@ SWAP >R um+ R> OR
@                       IF >R DROP 1+ R> THEN
@                       ELSE DROP THEN
@                       R>
@                  LOOP DROP SWAP EXIT
@               ELSE -11 THROW          \ result out of range
@               THEN @

		$COLON  6,'UM/MOD',UMSlashMOD,_FLINK
		DW      DUPP,ZBranch,UMM5
		DW      TwoDUP,ULess,ZBranch,UMM4
		DW      NEGATE,DoLIT,CELLL*8,Zero,DoDO
UMM1            DW      ToR,DUPP,UMPlus,ToR,ToR,DUPP,UMPlus,RFrom,Plus,DUPP
		DW      RFrom,RFetch,SWAP,ToR,UMPlus,RFrom,ORR,ZBranch,UMM2
		DW      ToR,DROP,OnePlus,RFrom,Branch,UMM3
UMM2            DW      DROP
UMM3            DW      RFrom,DoLOOP,UMM1
		DW      DROP,SWAP,EXIT
UMM5            DW      DoLIT,-10,THROW
UMM4            DW      DoLIT,-11,THROW

@   UNLOOP      ( -- ) ( R: loop-sys -- )       \ CORE
@               Discard loop-control parameters for the current nesting level.
@               An UNLOOP is required for each nesting level before the
@               definition may be EXITed.
@
@   : UNLOOP    R> R> R> 2DROP >R @

@		$COLON  COMPO+6,'UNLOOP',UNLOOP,_FLINK
@		DW      RFrom,RFrom,RFrom,TwoDROP,ToR,EXIT

		$CODE   COMPO+6,'UNLOOP',UNLOOP,_FLINK
		@The code version doesn't save fpc on return stack so
		@it doesn't have to do the same save/restore as the
		@colon version
		popR    r0
		popR    r0      @TODO can just bump it up
		$NEXT

@   WITHIN      ( n1|u1 n2|n2 n3|u3 -- flag )   \ CORE EXT
@               Return true if (n2|u2<=n1|u1 and n1|u1<n3|u3) or
@               (n2|u2>n3|u3 and (n2|u2<=n1|u1 or n1|u1<n3|u3)).
@
@   : WITHIN    OVER - >R - R> U< @

		$COLON  6,'WITHIN',WITHIN,_FLINK
		DW      OVER,Minus,ToR                  @ul <= u < uh
		DW      Minus,RFrom,ULess,EXIT

@   [           ( -- )                          \ CORE
@               Enter interpretation state.
@
@   : [         0 STATE ! @ COMPILE-ONLY IMMEDIATE

@               $COLON  IMMED+COMPO+1,'[',LeftBracket,_FLINK
@               DW      Zero,STATE,Store,EXIT

		$CODE   IMMED+COMPO+1,'[',LeftBracket,_FLINK
		ldr     r0,=LocSTATE
		mov     r1,#0
		str     r1,[r0]
		$NEXT

@   ]           ( -- )                          \ CORE
@               Enter compilation state.
@
@   : ]         -1 STATE ! @

@               $COLON  1,']',RightBracket,_FLINK
@               DW      MinusOne,STATE,Store,EXIT

		$CODE   1,']',RightBracket,_FLINK
		ldr     r0,=LocSTATE
		mov     r1,#-1
		str     r1,[r0]
		$NEXT

@@@@@@@@@@@@@@@@
@ Rest of CORE words and two facility words, EKEY? and EMIT?
@@@@@@@@@@@@@@@@
@       Following definitions can be removed from assembler source and
@       can be colon-defined later.

@   (           ( "ccc<)>" -- )                 \ CORE
@               Ignore following string up to next ) . A comment.
@
@   : (         [CHAR] ) PARSE 2DROP @

		$COLON  IMMED+1,'(',Paren,_FLINK
		DW      DoLIT,')',PARSE,TwoDROP,EXIT

@   *           ( n1|u1 n2|u2 -- n3|u3 )        \ CORE
@               Multiply n1|u1 by n2|u2 giving a single product.
@
@   : *         UM* DROP @

@               $COLON  1,'*',Star,_FLINK
@               DW      UMStar,DROP,EXIT

		$CODE   1,'*',Star,_FLINK
		popD    r0
		mul     tos, r0, tos
		$NEXT

@   */          ( n1 n2 n3 -- n4 )              \ CORE
@               Multiply n1 by n2 producing double-cell intermediate,
@               then divide it by n3. Return single-cell quotient.
@
@   : */        */MOD NIP @

		$COLON  2,'*/',StarSlash,_FLINK
		DW      StarSlashMOD,NIP,EXIT

@   */MOD       ( n1 n2 n3 -- n4 n5 )           \ CORE
@               Multiply n1 by n2 producing double-cell intermediate,
@               then divide it by n3. Return single-cell remainder and
@               single-cell quotient.
@
@   : */MOD     >R M* R> FM/MOD @

		$COLON  5,'*/MOD',StarSlashMOD,_FLINK
		DW      ToR,MStar,RFrom,FMSlashMOD,EXIT

@   +LOOP       Compilation: ( C: do-sys -- )   \ CORE
@               Run-time: ( n -- ) ( R: loop-sys1 -- | loop-sys2 )
@               Terminate a DO-+LOOP structure. Resolve the destination of all
@               unresolved occurences of LEAVE.
@               On execution add n to the loop index. If loop index did not
@               cross the boundary between loop_limit-1 and loop_limit,
@               continue execution at the beginning of the loop. Otherwise,
@               finish the loop.
@
@   : +LOOP     POSTPONE do+LOOP  rake @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'+LOOP',PlusLOOP,_FLINK
		DW      DoLIT,DoPLOOP,COMPILEComma,rake,EXIT

@   ."          ( "ccc<">" -- )                 \ CORE
@               Run-time ( -- )
@               Compile an inline string literal to be typed out at run time.
@
@   : ."        POSTPONE S" POSTPONE TYPE @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+2,'."',DotQuote,_FLINK
		DW      SQuote,DoLIT,TYPEE,COMPILEComma,EXIT

@   2OVER       ( x1 x2 x3 x4 -- x1 x2 x3 x4 x1 x2 )      \ CORE
@               Copy cell pair x1 x2 to the top of the stack.
@
@   : 2OVER     >R >R 2DUP R> R> 2SWAP @

@		$COLON  5,'2OVER',TwoOVER,_FLINK
@		DW      ToR,ToR,TwoDUP,RFrom,RFrom,TwoSWAP,EXIT

		$CODE   5,'2OVER',TwoOVER,_FLINK
		pushD   tos
		ldr     r0, [dsp, #+(CELLL*3)] @x1
		ldr     tos, [dsp, #+(CELLL*2)] @x2
		pushD   r0
		$NEXT

@   >BODY       ( xt -- a-addr )                \ CORE
@               Push data field address of CREATEd word.
@               Structure of CREATEd word:
@                       | call-doCREATE | 0 or DOES> code addr | a-addr |
@
@   : >BODY     ?call DUP IF                    \ code-addr xt2
@                   ['] doCREATE = IF           \ should be call-doCREATE
@                   CELL+ @ EXIT
@               THEN THEN
@               -31 THROW @             \ >BODY used on non-CREATEd definition

		$COLON  5,'>BODY',ToBODY,_FLINK
		DW      QCall,DUPP,ZBranch,TBODY1
		DW      DoLIT,DoCREATE,Equals,ZBranch,TBODY1
		DW      CELLPlus,Fetch,EXIT
TBODY1          DW      DoLIT,-31,THROW

@   ABORT"      ( "ccc<">" -- )                 \ EXCEPTION EXT
@               Run-time ( i*x x1 -- | i*x ) ( R: j*x -- | j*x )
@               Conditional abort with an error message.
@
@   : ABORT"    S" POSTPONE ROT
@               POSTPONE IF POSTPONE abort"msg POSTPONE 2!
@               -2 POSTPONE LITERAL POSTPONE THROW
@               POSTPONE ELSE POSTPONE 2DROP POSTPONE THEN
@               @  COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+6,'ABORT"',ABORTQuote,_FLINK
		DW      SQuote,DoLIT,ROT,COMPILEComma
		DW      IFF,DoLIT,AbortQMsg,COMPILEComma @ IF is immediate
		DW      DoLIT,TwoStore,COMPILEComma
		DW      DoLIT,-2,LITERAL                 @ LITERAL is immediate
		DW      DoLIT,THROW,COMPILEComma         @ throw -2 .. abort
		DW      ELSEE,DoLIT,TwoDROP,COMPILEComma @ ELSE and THEN are
		DW      THENN,EXIT                       @ immediate

@   ABS         ( n -- u )                      \ CORE
@               Return the absolute value of n.
@
@   : ABS       DUP 0< IF NEGATE THEN @

@		$COLON  3,'ABS',ABSS,_FLINK
@		DW      DUPP,ZeroLess,ZBranch,ABS1
@		DW      NEGATE
@ABS1            DW      EXIT

		$CODE   3,'ABS',ABSS,_FLINK
		orrs	tos,tos,#0		@set flags
		ldr	r0,=0
		submi   tos,r0,tos
		$NEXT

@   ALLOT       ( n -- )                        \ CORE
@               Allocate n bytes in RAM or ROM data space.
@
@   : ALLOT     hereVar +! @

@               $COLON  5,'ALLOT',ALLOT,_FLINK
@               DW      HereVar,PlusStore,EXIT

		$CODE   5,'ALLOT',ALLOT,_FLINK
		ldr     r0,=LocHereVar
		ldr     r1,[r0] @point to ROM or RAM pointer
		ldr     r2,[r1] @get its value
		add     r2,tos,r2
		popD    tos
		str     r2,[r1]
		$NEXT

@   BEGIN       ( C: -- dest )                  \ CORE
@               Start an infinite or indefinite loop structure. Put the next
@               location for a transfer of control, dest, onto the data
@               control stack.
@
@   : BEGIN     xhere 0 bal+            \ dest type is 0
@               @ COMPILE-ONLY IMMDEDIATE

		$COLON  IMMED+COMPO+5,'BEGIN',BEGIN,_FLINK
		DW      XHere,Zero,BalPlus,EXIT

@   C,          ( char -- )                     \ CORE
@               Compile a character into data space.
@
@   : C,        HERE C! char-size hereVar +! @

@               $COLON  2,'C,',CComma,_FLINK
@               DW      HERE,CStore,DoLIT,CHARR,HereVar,PlusStore,EXIT

		$CODE   2,'C,',CComma,_FLINK
		ldr     r0,=LocHereVar
		ldr     r1,[r0] @point to ROM or RAM pointer
		ldr     r2,[r1] @get its value
		strb    tos,[r2],#CHARR
		str     r2,[r1]
		popD    tos
		$NEXT

@   CHAR        ( "<spaces>ccc" -- char )       \ CORE
@               Parse next word and return the value of first character.
@
@   : CHAR      PARSE-WORD DROP C@ @

		$COLON  4,'CHAR',CHAR,_FLINK
		DW      PARSE_WORD,DROP,CFetch,EXIT

@   DO          Compilation: ( C: -- do-sys )   \ CORE
@               Run-time: ( n1|u1 n2|u2 -- ) ( R: -- loop-sys )
@               Start a DO-LOOP structure in a colon definition. Place do-sys
@               on control-flow stack, which will be resolved by LOOP or +LOOP.
@
@   : DO        0 rakeVar !  0                  \ ?DO-orig is 0 for DO
@               POSTPONE doDO xhere  bal+       \ DO-dest
@               @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+2,'DO',DO,_FLINK
		DW      Zero,RakeVar,Store,Zero
		DW      DoLIT,DoDO,COMPILEComma,XHere,BalPlus,EXIT

@   DOES>       ( C: colon-sys1 -- colon-sys2 ) \ CORE
@               Build run time code of the data object CREATEd.
@
@   : DOES>     bal 1- IF -22 THROW THEN        \ control structure mismatch
@               NIP 1+ IF -22 THROW THEN        \ colon-sys type is -1
@               POSTPONE pipe ['] doLIST xt, -1 @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'DOES>',DOESGreater,_FLINK
		DW      Bal,OneMinus,ZBranch,DOES1
		DW      DoLIT,-22,THROW
DOES1           DW      NIP,OnePlus,ZBranch,DOES2
		DW      DoLIT,-22,THROW
DOES2           DW      DoLIT,Pipe,COMPILEComma
		DW      DoLIT,DoLIST,xtComma,DoLIT,-1,EXIT

@   ELSE        Compilation: ( C: orig1 -- orig2 )      \ CORE
@               Run-time: ( -- )
@               Start the false clause in an IF-ELSE-THEN structure.
@               Put the location of new unresolved forward reference orig2
@               onto control-flow stack.
@
@   : ELSE      POSTPONE AHEAD 2SWAP POSTPONE THEN @ COMPILE-ONLY IMMDEDIATE

		$COLON  IMMED+COMPO+4,'ELSE',ELSEE,_FLINK
		DW      AHEAD,TwoSWAP,THENN,EXIT

@   ENVIRONMENT?   ( c-addr u -- false | i*x true )     \ CORE
@               Environment query.
@
@   : ENVIRONMENT?
@               envQList SEARCH-WORDLIST
@               DUP >R IF EXECUTE THEN R> @

		$COLON  12,'ENVIRONMENT?',ENVIRONMENTQuery,_FLINK
		DW      EnvQList,SEARCH_WORDLIST
		DW      DUPP,ToR,ZBranch,ENVRN1
		DW      EXECUTE
ENVRN1          DW      RFrom,EXIT

@   EVALUATE    ( i*x c-addr u -- j*x )         \ CORE
@               Evaluate the string. Save the input source specification.
@               Store -1 in SOURCE-ID.
@
@   : EVALUATE  SOURCE >R >R >IN @ >R  SOURCE-ID >R
@               -1 TO SOURCE-ID
@               sourceVar 2!  0 >IN !  interpret
@               R> TO SOURCE-ID
@               R> >IN ! R> R> sourceVar 2! @

		$COLON  8,'EVALUATE',EVALUATE,_FLINK
		DW      SOURCE,ToR,ToR,ToIN,Fetch,ToR,SOURCE_ID,ToR
		DW      MinusOne,DoTO,AddrSOURCE_ID
		DW      SourceVar,TwoStore,Zero,ToIN,Store,Interpret
		DW      RFrom,DoTO,AddrSOURCE_ID
		DW      RFrom,ToIN,Store,RFrom,RFrom,SourceVar,TwoStore,EXIT

@   FILL        ( c-addr u char -- )            \ CORE
@               Store char in each of u consecutive characters of memory
@               beginning at c-addr.
@
@   : FILL      ROT ROT ?DUP IF 0 DO 2DUP C! CHAR+ LOOP THEN 2DROP @

@		$COLON  4,'FILL',FILL,_FLINK
@		DW      ROT,ROT,QuestionDUP,ZBranch,FILL2
@		DW      Zero,DoDO
@FILL1           DW      TwoDUP,CStore,CHARPlus,DoLOOP,FILL1
@FILL2           DW      TwoDROP,EXIT

		$CODE   4,'FILL',FILL,_FLINK
		@ tos holds char
		popD    r0      @count
		popD    r1      @dest
		orrs    r0,r0,r0@drop straight through if length is 0
01              strneb  tos,[r1],#CHARR
		subnes  r0,r0,#CHARR
		bne     %b01
		popD    tos
		$NEXT

@   FIND        ( c-addr -- c-addr 0 | xt 1 | xt -1)     \ SEARCH
@               Search dictionary for a match with the given counted name.
@               Return execution token and -1 or 1 ( IMMEDIATE) if found@
@               c-addr 0 if not found.
@
@   : FIND      DUP COUNT search-word ?DUP IF NIP ROT DROP EXIT THEN
@               2DROP 0 @

		$COLON  4,'FIND',FIND,_FLINK
		DW      DUPP,COUNT,Search_word,QuestionDUP,ZBranch,FIND1
		DW      NIP,ROT,DROP,EXIT
FIND1           DW      TwoDROP,Zero,EXIT

@   IMMEDIATE   ( -- )                          \ CORE
@               Make the most recent definition an immediate word.
@
@   : IMMEDIATE   lastName [ =imed ] LITERAL OVER @ OR SWAP ! @

@               $COLON  9,'IMMEDIATE',IMMEDIATE,_FLINK
@               DW      LastName,DoLIT,IMMED,OVER,Fetch,ORR,SWAP,Store,EXIT

		$CODE   9,'IMMEDIATE',IMMEDIATE,_FLINK
		ldr     r0,=AddrNPVar
		ldr     r1,[r0]
		ldr     r2,[r1]
		add     r2,r2,#(CELLL*2)        @Lastname
		ldr     r3,[r2]                 @get length
		orr     r3,r3,#IMMED            @set flag
		str     r3,[r2]
		$NEXT

@   J           ( -- n|u ) ( R: loop-sys -- loop-sys )  \ CORE
@               Push the index of next outer loop.
@
@   : J         rp@ [ 3 CELLS ] LITERAL + @
@               rp@ [ 4 CELLS ] LITERAL + @  +  @ COMPILE-ONLY

@               $COLON  COMPO+1,'J',J,_FLINK
@               DW      RPFetch,DoLIT,3*CELLL,Plus,Fetch
@               DW      RPFetch,DoLIT,4*CELLL,Plus,Fetch,Plus,EXIT

		$CODE   COMPO+1,'J',J,_FLINK
		pushD   tos
		ldr     r0,[rsp, #(CELLL*2)] @note that we're one CELLL closer to the tos in CODE
		ldr     tos,[rsp, #(CELLL*3)]
		add     tos,tos,r0
		$NEXT

@   LEAVE       ( -- ) ( R: loop-sys -- )       \ CORE
@               Terminate definite loop, DO|?DO  ... LOOP|+LOOP, immediately.
@
@   : LEAVE     POSTPONE UNLOOP POSTPONE branch
@               xhere rakeVar DUP @ code, ! @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'LEAVE',LEAVEE,_FLINK
		DW      DoLIT,UNLOOP,COMPILEComma,DoLIT,Branch,COMPILEComma
		DW      XHere,RakeVar,DUPP,Fetch,CodeComma,Store,EXIT

@   LOOP        Compilation: ( C: do-sys -- )   \ CORE
@               Run-time: ( -- ) ( R: loop-sys1 -- loop-sys2 )
@               Terminate a DO|?DO ... LOOP structure. Resolve the destination
@               of all unresolved occurences of LEAVE.
@
@   : LOOP      POSTPONE doLOOP  rake @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+4,'LOOP',LOOPP,_FLINK
		DW      DoLIT,DoLOOP,COMPILEComma,rake,EXIT

@   LSHIFT      ( x1 u -- x2 )                  \ CORE
@               Perform a logical left shift of u bit-places on x1, giving x2.
@               Put 0 into the least significant bits vacated by the shift.
@
@   : LSHIFT    ?DUP IF 0 DO 2* LOOP THEN @

@               $COLON  6,'LSHIFT',LSHIFT,_FLINK
@               DW      QuestionDUP,ZBranch,LSHIFT2
@               DW      Zero,DoDO
@LSHIFT1        DW      TwoStar,DoLOOP,LSHIFT1
@LSHIFT2        DW      EXIT

		$CODE   6,'LSHIFT',LSHIFT,_FLINK
		popD    r0
		mov     tos, r0, lsl tos
		$NEXT

@   M*          ( n1 n2 -- d )                  \ CORE
@               Signed multiply. Return double product.
@
@   : M*        2DUP XOR 0< >R ABS SWAP ABS UM* R> IF DNEGATE THEN @

@               $COLON  2,'M*',MStar,_FLINK
@               DW      TwoDUP,XORR,ZeroLess,ToR,ABSS,SWAP,ABSS
@               DW      UMStar,RFrom,ZBranch,MSTAR1
@               DW      DNEGATE
@MSTAR1         DW      EXIT

		$CODE   2,'M*',MStar,_FLINK
		popD    r0
		smull   r1, tos, r0, tos
		pushD   r1                      @ms 32-bits are at top of stack
		$NEXT

@   MAX         ( n1 n2 -- n3 )                 \ CORE
@               Return the greater of two top stack items.
@
@   : MAX       2DUP < IF SWAP THEN DROP @

@               $COLON  3,'MAX',MAX,_FLINK
@               DW      TwoDUP,LessThan,ZBranch,MAX1
@               DW      SWAP
@MAX1           DW      DROP,EXIT

		$CODE   3,'MAX',MAX,_FLINK
		popD    r0
		cmp     r0,tos
		movgt   tos,r0
		$NEXT

@   MIN         ( n1 n2 -- n3 )                 \ CORE
@               Return the smaller of top two stack items.
@
@   : MIN       2DUP > IF SWAP THEN DROP @

@               $COLON  3,'MIN',MIN,_FLINK
@               DW      TwoDUP,GreaterThan,ZBranch,MIN1
@               DW      SWAP
@MIN1           DW      DROP,EXIT

		$CODE   3,'MIN',MIN,_FLINK
		popD    r0
		cmp     r0,tos
		movlt   tos,r0
		$NEXT

@   MOD         ( n1 n2 -- n3 )                 \ CORE
@               Divide n1 by n2, giving the single cell remainder n3.
@               Returns modulo of floored division in this implementation.
@
@   : MOD       /MOD DROP @

		$COLON  3,'MOD',MODD,_FLINK
		DW      SlashMOD,DROP,EXIT

@   PICK        ( x_u ... x1 x0 u -- x_u ... x1 x0 x_u )        \ CORE EXT
@               Remove u and copy the uth stack item to top of the stack. An
@               ambiguous condition exists if there are less than u+2 items
@               on the stack before PICK is executed.
@
@   : PICK      DEPTH DUP 2 < IF -4 THROW THEN    \ stack underflow
@               2 - OVER U< IF -4 THROW THEN
@               1+ CELLS sp@ + @ @

		$COLON  4,'PICK',PICK,_FLINK
		DW      DEPTH,DUPP,DoLIT,2,LessThan,ZBranch,PICK1
		DW      DoLIT,-4,THROW
PICK1           DW      DoLIT,2,Minus,OVER,ULess,ZBranch,PICK2
		DW      DoLIT,-4,THROW
PICK2           DW      OnePlus,CELLS,SPFetch,Plus,Fetch,EXIT

@   POSTPONE    ( "<spaces>name" -- )           \ CORE
@               Parse name and find it. Append compilation semantics of name
@               to current definition.
@
@   : POSTPONE  (') 0< IF POSTPONE LITERAL
@                         POSTPONE COMPILE, EXIT THEN   \ non-IMMEDIATE
@               COMPILE, @ COMPILE-ONLY IMMEDIATE       \ IMMEDIATE

		$COLON  IMMED+COMPO+8,'POSTPONE',POSTPONE,_FLINK
		DW      ParenTick,ZeroLess,ZBranch,POSTP1
		DW      LITERAL,DoLIT,COMPILEComma
POSTP1          DW      COMPILEComma,EXIT

@   RECURSE     ( -- )                          \ CORE
@               Append the execution semactics of the current definition to
@               the current definition.
@
@   : RECURSE   bal 1- 2* PICK 1+ IF -22 THROW THEN
@                       \ control structure mismatch@ colon-sys type is -1
@               bal 1- 2* 1+ PICK       \ xt of current definition
@               COMPILE, @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+7,'RECURSE',RECURSE,_FLINK
		DW      Bal,OneMinus,TwoStar,PICK,OnePlus,ZBranch,RECUR1
		DW      DoLIT,-22,THROW
RECUR1          DW      Bal,OneMinus,TwoStar,OnePlus,PICK
		DW      COMPILEComma,EXIT

@   REPEAT      ( C: orig dest -- )             \ CORE
@               Terminate a BEGIN-WHILE-REPEAT indefinite loop. Resolve
@               backward reference dest and forward reference orig.
@
@   : REPEAT    AGAIN THEN @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+6,'REPEAT',REPEATT,_FLINK
		DW      AGAIN,THENN,EXIT

@   RSHIFT      ( x1 u -- x2 )                  \ CORE
@               Perform a logical right shift of u bit-places on x1, giving x2.
@               Put 0 into the most significant bits vacated by the shift.
@
@   : RSHIFT    ?DUP IF
@                       0 SWAP  cell-size-in-bits SWAP -
@                       0 DO  2DUP D+  LOOP
@                       NIP
@                    THEN @

@               $COLON  6,'RSHIFT',RSHIFT,_FLINK
@               DW      QuestionDUP,ZBranch,RSHIFT2
@               DW      Zero,SWAP,DoLIT,CELLL*8,SWAP,Minus,Zero,DoDO
@RSHIFT1        DW      TwoDUP,DPlus,DoLOOP,RSHIFT1
@               DW      NIP
@RSHIFT2        DW      EXIT

		$CODE   6,'RSHIFT',RSHIFT,_FLINK
		popD    r0
		mov     tos, r0, lsr tos
		$NEXT

@   SLITERAL    ( c-addr1 u -- )                \ STRING
@               Run-time ( -- c-addr2 u )
@               Compile a string literal. Return the string on execution.
@
@   : SLITERAL  DUP LITERAL POSTPONE doS"
@               CHARS xhere 2DUP + ALIGNED TOxhere
@               SWAP MOVE @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+8,'SLITERAL',SLITERAL,_FLINK
		DW      DUPP,LITERAL,DoLIT,DoSQuote,COMPILEComma
		DW      CHARS,XHere,TwoDUP,Plus,ALIGNED,TOXHere
		DW      SWAP,MOVE,EXIT

@   S"          Compilation: ( "ccc<">" -- )    \ CORE
@               Run-time: ( -- c-addr u )
@               Parse ccc delimetered by " . Return the string specification
@               c-addr u on execution.
@
@   : S"        [CHAR] " PARSE POSTPONE SLITERAL @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+2,'S"',SQuote,_FLINK
		DW      DoLIT,'"',PARSE,SLITERAL,EXIT

@   SM/REM      ( d n1 -- n2 n3 )               \ CORE
@               Symmetric divide of double by single. Return remainder n2
@               and quotient n3.
@
@   : SM/REM    2DUP XOR >R OVER >R >R DUP 0< IF DNEGATE THEN
@               R> ABS UM/MOD
@               R> 0< IF SWAP NEGATE SWAP THEN
@               R> 0< IF        \ negative quotient
@                   NEGATE 0 OVER < 0= IF EXIT THEN
@                   -11 THROW                   THEN    \ result out of range
@               DUP 0< IF -11 THROW THEN @              \ result out of range

		$COLON  6,'SM/REM',SMSlashREM,_FLINK
		DW      TwoDUP,XORR,ToR,OVER,ToR,ToR,DUPP,ZeroLess
		DW      ZBranch,SMREM1
		DW      DNEGATE
SMREM1          DW      RFrom,ABSS,UMSlashMOD
		DW      RFrom,ZeroLess,ZBranch,SMREM2
		DW      SWAP,NEGATE,SWAP
SMREM2          DW      RFrom,ZeroLess,ZBranch,SMREM3
		DW      NEGATE,DoLIT,0,OVER,LessThan,ZeroEquals,ZBranch,SMREM4
SMREM5          DW      EXIT
SMREM3          DW      DUPP,ZeroLess,ZBranch,SMREM5
SMREM4          DW      DoLIT,-11,THROW

@   SPACES      ( n -- )                        \ CORE
@               Send n spaces to the output device if n is greater than zero.
@
@   : SPACES    ?DUP IF 0 DO SPACE LOOP THEN @

		$COLON  6,'SPACES',SPACES,_FLINK
		DW      QuestionDUP,ZBranch,SPACES2
		DW      Zero,DoDO
SPACES1         DW      SPACE,DoLOOP,SPACES1
SPACES2         DW      EXIT

@   TO          Interpretation: ( x "<spaces>name" -- ) \ CORE EXT
@               Compilation:    ( "<spaces>name" -- )
@               Run-time:       ( x -- )
@               Store x in name.
@
@   : TO        ' ?call DUP IF          \ should be call-doVALUE
@                 ['] doVALUE =         \ verify VALUE marker
@                 IF @ STATE @
@                    IF POSTPONE doTO code, EXIT THEN
@                    ! EXIT
@                    THEN THEN
@               -32 THROW @ IMMEDIATE   \ invalid name argument (e.g. TO xxx)

		$COLON  IMMED+2,'TO',TO,_FLINK
		DW      Tick,QCall,DUPP,ZBranch,TO1
		DW      DoLIT,DoVALUE,Equals,ZBranch,TO1
		DW      Fetch,STATE,Fetch,ZBranch,TO2
		DW      DoLIT,DoTO,COMPILEComma,CodeComma,EXIT
TO2             DW      Store,EXIT
TO1             DW      DoLIT,-32,THROW

@   U.          ( u -- )                        \ CORE
@               Display u in free field format followed by space.
@
@   : U.        0 D. @

@               $COLON  2,'U.',UDot,_FLINK
@               DW      Zero,DDot,EXIT

		$CODE   2,'U.',UDot,_FLINK
		pushD   tos
		mov     tos,#0
		b       DDot

@   UNTIL       ( C: dest -- )                  \ CORE
@               Terminate a BEGIN-UNTIL indefinite loop structure.
@
@   : UNTIL     IF -22 THROW THEN  \ control structure mismatch@ dest type is 0
@               POSTPONE 0branch code, bal- @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'UNTIL',UNTIL,_FLINK
		DW      ZBranch,UNTIL1
		DW      DoLIT,-22,THROW
UNTIL1          DW      DoLIT,ZBranch,COMPILEComma,CodeComma,BalMinus,EXIT

@   VALUE       ( x "<spaces>name" -- )         \ CORE EXT
@               name Execution: ( -- x )
@               Create a value object with initial value x.
@
@   : VALUE     bal IF -29 THROW THEN           \ compiler nesting
@               ['] doVALUE xt, head,
@               xhere DUP CELL+ TOxhere
@               RAMB @ SWAP !
@               , linkLast @ \ store x and link VALUE word to current wordlist

		$COLON  5,'VALUE',VALUE,_FLINK
		DW      Bal,ZBranch,VALUE1
		DW      DoLIT,-29,THROW
VALUE1          DW      DoLIT,DoVALUE,xtComma,HeadComma
		DW      XHere,DUPP,CELLPlus,TOXHere,RAMB,Fetch,SWAP,Store
		DW      Comma,LinkLast,EXIT

@   VARIABLE    ( "<spaces>name" -- )           \ CORE
@               name Execution: ( -- a-addr )
@               Parse a name and create a variable with the name.
@               Resolve one cell of data space at an aligned address.
@               Return the address on execution.
@
@   : VARIABLE  bal IF -29 THROW THEN           \ compiler nesting
@               ['] doCONST xt, head,
@               xhere DUP CELL+ TOxhere
@               RAMB @ DUP CELL+ RAMB ! \ allocate one cell in RAM area
@               SWAP ! linkLast @

		$COLON  8,'VARIABLE',VARIABLE,_FLINK
		DW      Bal,ZBranch,VARIA1
		DW      DoLIT,-29,THROW
VARIA1          DW      DoLIT,DoCONST,xtComma,HeadComma
		DW      XHere,DUPP,CELLPlus,TOXHere
		DW      RAMB,Fetch,DUPP,CELLPlus,RAMB,Store
		DW      SWAP,Store,LinkLast,EXIT

@   WHILE       ( C: dest -- orig dest )        \ CORE
@               Put the location of a new unresolved forward reference orig
@               onto the control flow stack under the existing dest. Typically
@               used in BEGIN ... WHILE ... REPEAT structure.
@
@   : WHILE     POSTPONE IF 2SWAP @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+5,'WHILE',WHILEE,_FLINK
		DW      IFF,TwoSWAP,EXIT

@   WORD        ( char "<chars>ccc<char>" -- c-addr )   \ CORE
@               Skip leading delimeters and parse a word. Return the address
@               of a transient region containing the word as counted string.
@
@   : WORD      skipPARSE xhere pack" DROP xhere @

		$COLON  4,'WORD',WORDD,_FLINK
		DW      SkipPARSE,XHere,PackQuote,DROP,XHere,EXIT

@   [']         Compilation: ( "<spaces>name" -- )      \ CORE
@               Run-time: ( -- xt )
@               Parse name. Return the execution token of name on execution.
@
@   : [']       ' POSTPONE LITERAL @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+3,"[']",BracketTick,_FLINK
		DW      Tick,LITERAL,EXIT

@   [CHAR]      Compilation: ( "<spaces>name" -- )      \ CORE
@               Run-time: ( -- char )
@               Parse name. Return the value of the first character of name
@               on execution.
@
@   : [CHAR]    CHAR POSTPONE LITERAL @ COMPILE-ONLY IMMEDIATE

		$COLON  IMMED+COMPO+6,'[CHAR]',BracketCHAR,_FLINK
		DW      CHAR,LITERAL,EXIT

@   \           ( "ccc<eol>" -- )               \ CORE EXT
@               Parse and discard the remainder of the parse area.
@
@   : \         SOURCE >IN ! DROP @ IMMEDIATE

@               $COLON  IMMED+1,'\',Backslash,_FLINK
@               DW      SOURCE,ToIN,Store,DROP,EXIT

		$CODE   IMMED+1,'\',xBackslash,_FLINK
		ldr     r0,=LocSourceVar
		ldr     r1,[r0]
		ldr     r3,=LocToIN
		str     r1,[r3]
		$NEXT

		LTORG

@ Optional Facility words

@   EKEY?       ( -- flag )                     \ FACILITY EXT
@               If a keyboard event is available, return true.
@
@   : EKEY?     'ekey? EXECUTE @

		$COLON  5,'EKEY?',EKEYQuestion,_FLINK
		DW      TickEKEYQ,EXECUTE,EXIT

@   EMIT?       ( -- flag )                     \ FACILITY EXT
@               flag is true if the user output device is ready to accept data
@               and the execution of EMIT in place of EMIT? would not have
@               suffered an indefinite delay. If device state is indeterminate,
@               flag is true.
@
@   : EMIT?     'emit? EXECUTE @

		$COLON  5,'EMIT?',EMITQuestion,_FLINK
		DW      TickEMITQ,EXECUTE,EXIT

@@@@@@@@@@@@@@@@
@ RAM/ROM System Only
@@@@@@@@@@@@@@@@

@   RESET-SYSTEM   ( -- )
@               Reset the system. Restore initialization values of system
@               variables.
@
@   : RESET-SYSTEM
@               sysVar00 sysVar0 [ sysVar0End sysVar0 - ] LITERAL  MOVE COLD @

		$COLON  12,'RESET-SYSTEM',RESET_SYSTEM,_SLINK
		DW      DoLIT,UZERO0,SysVar0,DoLIT,ULAST-UZERO
		DW      MOVE,COLD,EXIT

UZERO0          DW      RXQ
		DW      RXFetch
		DW      TXQ
		DW      TXStore
		DW      Set_IO
		DW      DotOK
		DW      HI
		DW      IOBYTES
		DW      0
		DW      AddrROMB
		DW      AddrROMT
		DW      AddrRAMB
		DW      OptiCOMPILEComma
		DW      EXECUTE
		DW      DoubleAlsoComma
		DW      DoubleAlso
		DW      EXECUTE
		DW      EXECUTE
		DW      10
		DW      CTOP
		DW      NTOP
		DW      VTOP
		DW      RAMT0
		DW      0
		DW      0
		DW      0
		DW      2
		DW      FORTH_WORDLISTAddr
		DW      NONSTANDARD_WORDLISTAddr
		DS      (OrderDepth-2) * CELLL
		DW      FORTH_WORDLISTAddr
		DW      LASTFORTH
		DW      NONSTANDARD_WORDLISTAddr
		DW      FORTH_WORDLISTName
		DW      LASTSYSTEM
		DW      0
		DW      NONSTANDARD_WORDLISTName
		DS      3*(MaxWLISTS-2) * CELLL
		DW      LASTENV
		DW      SysUserP
		DW      SysUserP
		DS      CELLL
		DW      SystemTaskName
		DS      CELLL
		DS      CELLL
		DW      Wake
		DW      SysStatus
		DW      SPP
		DW      RPP

@===============================================================
@NAC: these are put in by makesrc.awk -- CTOP and VTOP are OK because _VAR
@NAC: is SETA to the right value as the awk script emits new source
@LASTENV         .equ     _ENVLINK-0
@LASTSYSTEM      .equ     _SLINK-0        @last SYSTEM word name address
@LASTFORTH       .equ     _FLINK-0        @last FORTH word name address

@NTOP            .equ     _NAME-0         @next available memory in name dictionary
CTOP            .equ     .-0             @next available memory in code dictionary
VTOP            .equ     _VAR-0          @next available memory in variable area

@nMAIN    ENDS
@nEND     ORIG

@===============================================================
