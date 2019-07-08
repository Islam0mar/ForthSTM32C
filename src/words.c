#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <string.h>
// #include "forth/words.h"




//   !IO		( -- )
//		Initialize the serial I/O devices.
/* /\* void STOIO(void) *\/ */
/* /\* { *\/ */
	
/* /\* } *\/ */

/* /\* //   ?RX		( -- c T | F ) *\/ */
/* /\* //		Return input character and true, or a false if no input. *\/ */
/* /\* void QRX(void) *\/ */
/* /\* { *\/ */
	
/* /\* } *\/ */

/* /\* //   TX!		( c -- ) *\/ */
/* /\* //		Send character c to the output device. *\/ */
/* /\* void TXSTO(void) *\/ */
/* /\* { *\/ */
	
/* /\* } *\/ */

/* /\* //// The kernel *\/ */

/* /\* //   doLIT	( -- w ) *\/ */
/* /\* //		Push an inline literal. *\/ */
/* /\* void DOLIT(void) *\/ */
/* /\* { *\/ */
/* /\* 	PSP--; *\/ */
/* /\* 	PS[PSP] = IP[0]; *\/ */
/* /\* 	IP++; *\/ */
/* /\* 	NEXT(); *\/ */
/* /\* } *\/ */

/* /\* //   doLIST	( a -- ) *\/ */
/* /\* //		Process colon list. *\/ */

/* /\* void DOLST(void) *\/ */


/* /\* //   EXIT	( -- ) *\/ */
/* /\* //		Terminate a colon definition. *\/ */

/* /\* void EXIT *\/ */


/* /\* //   EXECUTE	( ca -- ) *\/ */
/* /\* //		Execute the word at ca. *\/ */

/* /\* void EXECU *\/ */


/* /\* //   next	( -- ) *\/ */
/* /\* //		Run time code for the single index loop. *\/ */
/* /\* //		: next ( -- ) \ hilevel model *\/ */
/* /\* //		  r> r> dup if 1 - >r @ >r exit then drop cell+ >r // *\/ */

/* /\* void DONXT *\/ */


/* /\* //   ?branch	( f -- ) *\/ */
/* /\* //		Branch if flag is zero. *\/ */

/* /\* void QBRAN *\/ */

/* /\* //   branch	( -- ) *\/ */
/* /\* //		Branch to an inline address. *\/ */

/* /\* void BRAN *\/ */


/* /\* //   !		( w a -- ) *\/ */
/* /\* //		Pop the data stack to memory. *\/ */

/* /\* void STORE *\/ */


/* /\* //   @		( a -- w ) *\/ */
/* /\* //		Push memory location to the data stack. *\/ */

/* /\* void AT *\/ */


/* /\* //   C!		( c b -- ) *\/ */
/* /\* //		Pop the data stack to byte memory. *\/ */

/* /\* void CSTOR *\/ */


/* /\* //   C@		( b -- c ) *\/ */
/* /\* //		Push byte memory location to the data stack. *\/ */

/* /\* void CAT *\/ */


/* /\* //   RP@		( -- a ) *\/ */
/* /\* //		Push the current RP to the data stack. *\/ */

/* /\* void RPAT *\/ */

/* /\* //   RP!		( a -- ) *\/ */
/* /\* //		Set the return stack pointer. *\/ */

/* /\* void RPSTO *\/ */

/* /\* //   R>		( -- w ) *\/ */
/* /\* //		Pop the return stack to the data stack. *\/ */

/* /\* void RFROM *\/ */


/* /\* //   R@		( -- w ) *\/ */
/* /\* //		Copy top of return stack to the data stack. *\/ */

/* /\* void RAT *\/ */


/* /\* //   >R		( w -- ) *\/ */
/* /\* //		Push the data stack to the return stack. *\/ */

/* /\* void TOR *\/ */


/* /\* //   SP@		( -- a ) *\/ */
/* /\* //		Push the current data stack pointer. *\/ */

/* /\* void SPAT *\/ */


/* /\* //   SP!		( a -- ) *\/ */
/* /\* //		Set the data stack pointer. *\/ */

/* /\* void SPSTO *\/ */

/* /\* //   DROP	( w -- ) *\/ */
/* /\* //		Discard top stack item. *\/ */

/* /\* void DROP *\/ */


/* //   DUP		( w -- w w ) */
/* //		Duplicate the top stack item. */

/* void DUPP */

/* //   SWAP	( w1 w2 -- w2 w1 ) */
/* //		Exchange top two stack items. */

/* void SWAP */

/* //   OVER	( w1 w2 -- w1 w2 w1 ) */
/* //		Copy second stack item to top. */

/* void OVER */

/* //   0<		( n -- t ) */
/* //		Return true if n is negative. */

/* void ZLESS */

/* //   AND		( w w -- w ) */
/* //		Bitwise AND. */

/* void ANDD */


/* //   OR		( w w -- w ) */
/* //		Bitwise inclusive OR. */

/* void ORR */


/* //   XOR		( w w -- w ) */
/* //		Bitwise exclusive OR. */

/* void XORR */


/* //   UM+		( w w -- w cy ) */
/* //		Add two numbers, return the sum and carry flag. */

/* void UPLUS */




/* /\* @@ Reserve three special registers:  *\/ */
/* /\* @@ SP(r13) stack pointer *\/ */
/* /\* @@ LR(r14) link register *\/ */
/* /\* @@ PC(r15) interpreter pointer points to the next line of code which will be excuted *\/ */
/* /\* @@ PSR program status register *\/ */
/* /\* @       ARM register usage *\/ */
/* /\* col .req 	r7 		@ absolute address of docol *\/ */
/* /\* up	.req	r8		@ user area pointer *\/ */
/* /\* do	.req 	r9 		@ absolute address of dodoes *\/ */
/* /\* tos	.req	r10		@ top of data stack item *\/ */
/* /\* rsp	.req 	r11		@ RETURN stack pointer *\/ */
/* /\* fpc	.req 	r12		@ FORTH vm instruction ptr *\/ */
/* /\* dsp	.req 	r13		@ DATA stack pointer *\/ */

/* // NEXT macro */
/* // NOTE!! support only thumb mode imply that bx take register with LSB is 1 */
/* // ,so force .thumb_func for all labels */
/* /\* 	.macro NEXT *\/ */
/* /\* 	ldr pc, [fpc], #4 *\/ */
/* /\* 	.endm *\/ */
	
/* /\* /\\* DOCOL - the interpreter! *\\/ *\/ */
/* /\* 	.text *\/ */
/* /\* 	.align	1 *\/ */
/* /\* 	.p2align 2,,3 *\/ */
/* /\* 	.thumb *\/ */
/* /\* 	.thumb_func *\/ */
/* /\* 	.fpu softvfp *\/ */
/* /\* 	.type	DOCOL, %function *\/ */
/* /\* DOCOL: *\/ */
/* /\* 	pushR fpc		    @@ push fpc on to the return stack *\/ */
/* /\* 	sub fpc, lr, #1		@@ -1 due to thumb mode *\/ */
/* /\* 	NEXT *\/ */
	
/* /\* /\\* DODOES for OOP *\\/ *\/ */
/* /\* 	.text *\/ */
/* /\* 	.align	1 *\/ */
/* /\* 	.p2align 2,,3 *\/ */
/* /\* 	.thumb *\/ */
/* /\* 	.thumb_func *\/ */
/* /\* 	.fpu softvfp *\/ */
/* /\* 	.type	DODOES, %function *\/ */
/* /\* DODOES: *\/ */
/* /\* 	ldr r0, [lr, #-1]! *\/ */
/* /\* 	cbz r0, 1f					@ Is offset zero ? *\/ */
/* /\* 	pushR fpc 						@ push fpc on return stack *\/ */
/* /\* 	mov fpc, r0							@  Get pointer to behavior words *\/ */
/* /\* 1:	pushTOS							@ Push the pointer to its data *\/ */
/* /\* 	add tos, lr, #4					@ Data field pointer *\/ */
/* /\* 	NEXT *\/ */
	





/* /\* */
/* 	Most of the following code is taken from */
/* 	jonesforth port to arm with minimum  */
/* 	change to be direct threaded code */
/* 	*\/ */
/* @ */
/* 	defcode "EXIT",4,,EXIT */
/* 	popR fpc	            @ pop return stack into %esi */
/*     NEXT */

/* 	defcode "EXITISR",7,,EXITISR */
/* 	popR fpc	            @ pop return stack into fpc */
/* 	mrs r0, ipsr */
/* 	cbz r0, 1f */
/* 	ldr r0, = 0xfffffff9 */
/* 	bx r0 */
/* 1:	 */
/*     NEXT */
/*     .ltorg */
	
/* @ LIT is used to compile literals in forth word. */
/* @ When LIT is executed it pushes the literal (which is the next codeword) */
/* @ into the stack and skips it (since the literal is not executable). */

/*     defcode "LIT",3,F_COMPO,LIT */
/* 	pushTOS */
/*     ldr tos, [fpc], #4 */
/*     NEXT */

/* @@@ writes "b docol" for new words */
/* 	defcode "DOCOL,",6,F_COMPO,DOCOL_COMMA */
/* 	ldr r1, = QUIT */
/* 	ldrh r0, [r1, #-1] 			@ get "b docol"   */

/* 	ldr     r1, =var_DP */
/*     ldr     r2, [r1]        @ read DP */
	
/* 2:  strh     r0, [r2], #2    @ write value and increment address */
/*     str     r2, [r1]        @ update DP */
/*     NEXT */



/* /\* */
/* 	BUILT-IN VARIABLES ---------------------------------------------------------------------- */

/* 	These are some built-in variables and related standard FORTH words.  Of these, the only one that we */
/* 	have discussed so far was LATEST, which points to the last (most recently defined) word in the */
/* 	FORTH dictionary.  LATEST is also a FORTH word which pushes the address of LATEST (the variable) */
/* 	on to the stack, so you can read or write it using @ and ! operators.  For example, to print */
/* 	the current value of LATEST (and this can apply to any FORTH variable) you would do: */

/* 	LATEST @ . CR */

/* 	To make defining variables shorter, I'm using a macro called defvar, similar to defword and */
/* 	defcode above.  (In fact the defvar macro uses defcode to do the dictionary header). */
/* *\/ */

/* 	.macro defvar name, namelen, flags=0, label, initial=0 */
/* 	defcode \name,\namelen,\flags,\label */
/* 	pushTOS */
/* 	ldr tos, = var_\name */
/* 	NEXT */
/* 	.data */
/* 	.align	2 */
/* var_\name: */
/* 	.4byte \initial */
/* 	.endm */

/* /\* */
/* 	The built-in variables are: */

/* 	STATE		Is the interpreter executing code (0) or compiling a word (non-zero)? */
/* 	LATEST		Points to the latest (most recently defined) word in the dictionary. */
/* 	DP		Points to the next free byte of memory.  When compiling, compiled words go here. */
/* 	S0		Stores the address of the top of the parameter stack. */
/* 	BASE		The current base for printing and reading numbers. */

/* 	*\/ */
/* 	/\* RAM vector table*\/ */

/* 	defvar "STATE",5,,STATE */
/* 	defvar "DP",2,,DP */
/* 	defvar "FLASH",5,,FLASH		// latest flash position */
/* 	defvar "RAM",3,,RAM			// latest ram position  */
/* 	defvar "LATEST",6,,LATEST,name_QUIT @ latest defined word */
/* 	defvar "F_LATEST",8,,F_LATEST,name_QUIT @ latest defined word FLASH */
/* 	defvar "BASE",4,,BASE,10 */
/* 	defvar "S0",2,,SZ,__stack_end__ */
/* 	defvar "R0",2,,RZ,return_stack_top */
/* 	defvar "BOOT",4,,BOOT,QUIT */

/* 	defvar "FIFO",4,,_FIFO,FIFO */
/* 	defvar "FIFO_put",8,,_FIFO_put,0 */
/* 	defvar "FIFO_get",8,,_FIFO_get,0 */
	
/* 	.macro defconst name, namelen, flags=0, label, value */
/* 	defcode \name,\namelen,\flags,\label */
/* 	pushTOS */
/* 	ldr tos, = \value */
/* 	NEXT */
/* 	.endm */

/* 	defconst "FIFO_SIZE",9,,_FIFO_SIZE, FIFO_SIZE */
/* 	defconst "PAD",3,,PAD, word_buffer */

/* 	defconst "VERSION",7,,VERSION,SFORTH_VERSION */
/* 	defconst "F_IMMED",7,,__F_IMMED,F_IMMED */
/* 	defconst "F_COMPO",7,,__F_COMPO,F_COMPO */
/* 	defconst "F_HIDDEN",8,,__F_HIDDEN,F_HIDDEN */
/* 	defconst "F_LENMASK",9,,__F_LENMASK,F_LENMASK */

/* 	defconst "O_RDONLY",8,,__O_RDONLY,0 */
/* 	defconst "O_WRONLY",8,,__O_WRONLY,1 */
/* 	defconst "O_RDWR",6,,__O_RDWR,2 */
/* 	defconst "O_CREAT",7,,__O_CREAT,0100 */
/* 	defconst "O_EXCL",6,,__O_EXCL,0200 */
/* 	defconst "O_TRUNC",7,,__O_TRUNC,01000 */
/* 	defconst "O_APPEND",8,,__O_APPEND,02000 */
/* 	defconst "O_NONBLOCK",10,,__O_NONBLOCK,04000 */

/* 	defconst "__stack_end__",13,,foo0,vectorTable_RAM + 4*0 */
/* 	defconst "Reset_Handler",13,,foo1,vectorTable_RAM + 4*1  */
/* 	defconst "NMI_Handler",11,,foo2,vectorTable_RAM + 4*2  */
/* 	defconst "HardFault_Handler",17,,foo3,vectorTable_RAM + 4*3 */
/* 	.ltorg */
/* 	defconst "MemManage_Handler",17,,foo4,vectorTable_RAM + 4*4  */
/* 	defconst "BusFault_Handler",16,,foo5,vectorTable_RAM + 4*5  */
/* 	defconst "UsageFault_Handler",18,,foo6,vectorTable_RAM + 4*6  */
/* 	defconst "SVC_Handler",11,,foo7,vectorTable_RAM + 4*11  */
/* 	defconst "DebugMon_Handler",16,,foo8,vectorTable_RAM + 4*12  */
/* 	defconst "PendSV_Handler",14,,foo9,vectorTable_RAM + 4*14  */
/* 	defconst "SysTick_Handler",15,,foo10,vectorTable_RAM + 4*15  */
/* 	defconst "WWDG_IRQHandler",15,,foo11,vectorTable_RAM + 4*16 */
/* 	.ltorg */
/* 	defconst "PVD_IRQHandler",14,,foo12,vectorTable_RAM + 4*17    */
/* 	defconst "TAMPER_IRQHandler",17,,foo13,vectorTable_RAM + 4*18  */
/* 	defconst "RTC_IRQHandler",14,,foo14,vectorTable_RAM + 4*19  */
/* 	defconst "FLASH_IRQHandler",16,,foo15,vectorTable_RAM + 4*20  */
/* 	defconst "RCC_IRQHandler",14,,foo16,vectorTable_RAM + 4*21  */
/* 	defconst "EXTI0_IRQHandler",16,,foo17,vectorTable_RAM + 4*22  */
/* 	defconst "EXTI1_IRQHandler",16,,foo18,vectorTable_RAM + 4*23  */
/* 	defconst "EXTI2_IRQHandler",16,,foo19,vectorTable_RAM + 4*24  */
/* 	defconst "EXTI3_IRQHandler",16,,foo20,vectorTable_RAM + 4*25  */
/* 	defconst "EXTI4_IRQHandler",16,,foo21,vectorTable_RAM + 4*26  */
/* 	.ltorg */
/* 	defconst "DMA1_Channel1_IRQHandler",24,,foo22,vectorTable_RAM + 4*27  */
/* 	defconst "DMA1_Channel2_IRQHandler",24,,foo23,vectorTable_RAM + 4*28  */
/* 	defconst "DMA1_Channel3_IRQHandler",24,,foo24,vectorTable_RAM + 4*29  */
/* 	defconst "DMA1_Channel4_IRQHandler",24,,foo25,vectorTable_RAM + 4*30  */
/* 	defconst "DMA1_Channel5_IRQHandler",24,,foo26,vectorTable_RAM + 4*31  */
/* 	defconst "DMA1_Channel6_IRQHandler",24,,foo27,vectorTable_RAM + 4*32  */
/* 	defconst "DMA1_Channel7_IRQHandler",24,,foo28,vectorTable_RAM + 4*33  */
/* 	defconst "ADC1_2_IRQHandler",17,,foo29,vectorTable_RAM + 4*34  */
/* 	defconst "USB_HP_CAN1_TX_IRQHandler",25,,foo30,vectorTable_RAM + 4*35  */
/* 	defconst "USB_LP_CAN1_RX0_IRQHandler",26,,foo31,vectorTable_RAM + 4*36 */
/* 	defconst "CAN1_RX1_IRQHandler",19,,foo32,vectorTable_RAM + 4*37  */
/* 	defconst "CAN1_SCE_IRQHandler",19,,foo33,vectorTable_RAM + 4*38  */
/* 	defconst "EXTI9_5_IRQHandler",18,,foo34,vectorTable_RAM + 4*39  */
/* 	defconst "TIM1_BRK_IRQHandler",19,,foo35,vectorTable_RAM + 4*40  */
/* 	defconst "TIM1_UP_IRQHandler",18,,foo36,vectorTable_RAM + 4*41  */
/* 	defconst "TIM1_TRG_COM_IRQHandler",23,,foo37,vectorTable_RAM + 4*42 */
/* 	defconst "TIM1_CC_IRQHandler",18,,foo38,vectorTable_RAM + 4*43  */
/* 	defconst "TIM2_IRQHandler",15,,foo39,vectorTable_RAM + 4*44  */
/* 	defconst "TIM3_IRQHandler",15,,foo40,vectorTable_RAM + 4*45  */
/* 	defconst "TIM4_IRQHandler",15,,foo41,vectorTable_RAM + 4*46  */
/* 	defconst "I2C1_EV_IRQHandler",18,,foo42,vectorTable_RAM + 4*47 */
/* 	defconst "I2C1_ER_IRQHandler",18,,foo43,vectorTable_RAM + 4*48 */
/* 	defconst "I2C2_EV_IRQHandler",18,,foo44,vectorTable_RAM + 4*49 */
/* 	defconst "I2C2_ER_IRQHandler",18,,foo45,vectorTable_RAM + 4*50 */
/* 	defconst "SPI1_IRQHandler",15,,foo46,vectorTable_RAM + 4*51  */
/* 	defconst "SPI2_IRQHandler",15,,foo47,vectorTable_RAM + 4*52  */
/* 	defconst "USART1_IRQHandler",17,,foo48,vectorTable_RAM + 4*53  */
/* 	defconst "USART2_IRQHandler",17,,foo49,vectorTable_RAM + 4*54  */
/* 	defconst "USART3_IRQHandler",17,,foo50,vectorTable_RAM + 4*55  */
/* 	defconst "EXTI15_10_IRQHandler",20,,foo51,vectorTable_RAM + 4*56  */
/* 	defconst "RTC_Alarm_IRQHandler",20,,foo52,vectorTable_RAM + 4*57 */
/* 	defconst "USBWakeUp_IRQHandler",20,,foo53,vectorTable_RAM + 4*58 */
/* 	//defconst "BootRAM",7,,foo54,vectorTable_RAM + 4*66 */
/* 	/\* @0xF108F85F. This is for boot in RAM mode*\/ */



/* @ PAREN_FIND ( addr length -- dictionary_address ) */
/* @ Tries to find a word in the dictionary and returns its address. */
/* @ If the word is not found, NULL is returned. */

/* 	defcode "(FIND)",6,,PAREN_FIND */
/* 	mov r1, tos  @length */
/* 	pop {r0} @addr */
/*         bl _FIND */
/*         mov tos, r0 */
/*         NEXT */

/* _FIND: */
/*         stmfd   sp!, {r3,r4,r5,r6}      @ save callee save registers */
/*         ldr r2, =var_LATEST */
/*         ldr r3, [r2]                    @ get the last defined word address */
/* 	    mov r5, r0                      @ r5 contains searched string */

/* 1: */
/*         cmp r3, #0                      @ did we check all the words ? */
/*         beq 4f                          @ then exit */

/*         ldrb r2, [r3, #4]               @ read the length field */
/*         and r2, r2, #(F_HIDDEN|F_LENMASK) @ keep only length + hidden bits */
/*         cmp r2, r1                      @ do the lengths match ? */
/*                                         @ (note that if a word is hidden, */
/*                                         @  the test will be always negative) */
/*         bne 3f                          @ branch if they do not match */
/*                                         @ Now we compare strings characters */
/*         mov r6, r3                      @ r6 contains dict string */
/*         add r6, r6, #5                  @ (we skip link and length fields) */
/*                                         @ r2 contains the length */

/* 2: */
/*         ldrb r4, [r5], #1               @ compare character per character */
/*         ldrb r0, [r6], #1 */
/*     	cmp r4,r0 */
/* 		subne r2, r1, r2 */
/* 		addne r2, #1 */
/* 		subne r5, r2 */
/*         bne 3f                          @ if they do not match, branch to 3 */
/*         subs r2,r2,#1                   @ decrement length */
/*         bne 2b                          @ loop */

/*                                         @ here, strings are equal */
/*         b 4f                            @ branch to 4 */

/* 3: */
/*         ldr r3, [r3]                    @ Mismatch, follow link to the next */
/*         b 1b                            @ dictionary word */
/* 4: */
/*         mov r0, r3                      @ move result to r0 */
/*         ldmfd   sp!, {r3,r4,r5,r6}      @ restore callee save registers */
/*         bx lr */
/* @ >CFA ( dictionary_address -- executable_address ) */
/* @ Transformat a dictionary address into a code field address */

/* 	defcode ">CFA",4,,TCFA */
/* 	mov r0,tos */
/*         bl _TCFA */
/*         mov tos, r0 */
/*         NEXT */
/* _TCFA: */
/*         add r0,r0,#4            @ skip link field */
/*         ldrb r1, [r0], #1       @ load and skip the length field */
/*         and r1,r1,#F_LENMASK    @ keep only the length */
/*         add r0,r0,r1            @ skip the name field */
/*         add r0,r0,#3            @ find the next 4-byte boundary */
/*     	and r0,r0,#~3 */
/* 		add r0, #1				@ for thumb */
/*         bx lr */
	
/* @@@ >DFA ( dictionary_address -- data_field_address ) */
/* @@@ Return the address of the first data field */
/* 	defword ">DFA",4,,TDFA */
/* 	.4byte TCFA		// >CFA		(get code field address) */
/* 	.4byte INCR 	// 1+	(add 2 to it to get to next word) */
/* 	.4byte EXIT		// EXIT		(return from FORTH word) */

/* @ HEADER ( address length -- ) Creates a new dictionary entry */
/* @ in the data segment. */

/* 	defcode "HEADER,",7,F_COMPO,HEADER_COMMA */
/*         pop {r0}          @ address of the word to insert into the dictionnary */

/*         ldr r2,=var_DP */
/*         ldr r3,[r2]     @ load into r3 and r6 the location of the header */
/*         mov r6,r3 */

/*         ldr r4,=var_LATEST */
/*         ldr r5,[r4]     @ load into r5 the link pointer */

/*         str r5,[r3], #4     @ store link here -> last */

/*  //       add r3,r3,#4    @ skip link address */
/*         strb tos,[r3], #1    @ store the length of the word */
/*         //add r3,r3,#1    @ skip the length address */

/*         mov r5,#0       @ initialize the incrementation */

/* 1: */
/*         cmp r5,tos       @ if the word is completley read */
/*         beq 2f */

/*         ldrb r1,[r0],	#1 @ read and store a character */
/*         strb r1,[r3], 	#1 @ and skip the word */

/*         add r5,r5,#1    @ ready to rad the next character */

/*     	b 1b */

/* 2:       */
/* 		add r3,r3,#3            @ align to next 4 byte boundary */
/*         and r3,r3,#~3 */

/*         str r6,[r4]             @ update LATEST and HERE */
/*         str r3,[r2] */
/* 		popTOS */
/*         NEXT */

/*         @ , ( n -- ) writes the top element from the stack at DP */
/* 	defcode ",",1,,COMMA */
/* 	mov r0, tos */
/*         bl _COMMA */
/* 	popTOS */
/*         NEXT */
/* _COMMA: */
/*         ldr     r1, =var_DP */
/*         ldr     r2, [r1]        @ read DP */
/*         str     r0, [r2], #4    @ write value and increment address */
/*         str     r2, [r1]        @ update DP */
/*         bx      lr */
	
/* @ [ ( -- ) Change interpreter state to Immediate mode */
/* 	defcode "[",1,F_IMMED,LBRAC */
/* 	ldr     r0, =var_STATE */
/*     mov     r1, #0 */
/*     str     r1, [r0] */
/* 	NEXT */

/* @ ] ( -- ) Change interpreter state to Compilation mode */
/* 	defcode "]",1,,RBRAC */
/* 	ldr     r0, =var_STATE */
/*     mov     r1, #1 */
/*     str     r1, [r0] */
/* 	NEXT */

/* @ : ( -- ) Define a new forth word */
/* 	defword ":",1,,COLON */
/* 	.4byte WORD		// Get the name of the new word */
/* 	.4byte HEADER_COMMA	// Create the dictionary entry / header */
/* 	.4byte DOCOL_COMMA	// Append DOCOL  (the codeword). */
/* 	.4byte LATEST, FETCH, HIDDEN // Make the word hidden (see below for definition). */
/* 	.4byte RBRAC		// Go into compile mode. */
/* 	.4byte EXIT		// Return from the function. */

/* 	defword ";",1,F_IMMED+F_COMPO,SEMICOLON */
/* 	.4byte STATE, FETCH, TWODIV, ZBRANCH, 24 // goto normal ; */
/* 	.4byte LIT, EXITISR, COMMA,	BRANCH, 16 	// interrupt  */
/* 	.4byte LIT, EXIT, COMMA	// Append EXIT (so the word will return). */
/* 	.4byte LATEST, FETCH, HIDDEN // Toggle hidden flag -- unhide the word (see below for definition). */
/* 	.4byte LBRAC		// Go back to IMMEDIATE mode. */
/* 	.4byte ISFLASH */
/* 	.4byte EXIT		// Return from the function. */

/* @ IMMEDIATE ( -- ) sets IMMEDIATE flag of last defined word */
/* 	defcode "IMMEDIATE",9,F_COMPO+F_IMMED,IMMEDIATE */
/* 	ldr r0, =var_LATEST     @ */
/* 	ldr r1, [r0]            @ get the Last word */
/* 	add r1, r1, #4          @ points to the flag byte */
                                
/* 	mov r2, #0              @ */
/* 	ldrb r2, [r1]           @ load the flag into r2 */
/*                                 @ */
/* 	eor r2, r2, #F_IMMED    @ r2 = r2 xor F_IMMED */
/* 	strb r2, [r1]           @ update the flag */
/* 	NEXT */

/* @ COMPILE-ONLY ( -- ) sets COMPILEONLY flag of last defined word */
/* 	defcode "COMPILE-ONLY",12,F_COMPO+F_IMMED,COMPILE_ONLY */
/* 	ldr r0, =var_LATEST     @ */
/* 	ldr r1, [r0]            @ get the Last word */
/* 	add r1, r1, #4          @ points to the flag byte */
                                
/* 	mov r2, #0              @ */
/* 	ldrb r2, [r1]           @ load the flag into r2 */
/*                                 @ */
/* 	eor r2, r2, #F_COMPO    @ r2 = r2 xor F_COMPO */
/* 	strb r2, [r1]           @ update the flag */
/* 	NEXT */

/* @ HIDDEN ( dictionary_address -- ) sets HIDDEN flag of a word */
/* 	defcode "HIDDEN",6,,HIDDEN */
/*     ldr r1, [tos, #4]! */
/*     eor r1, r1, #F_HIDDEN */
/*     str r1, [tos] */
/* 	popTOS */
/* 	NEXT */

/* @ INTERRUPT ( -- ) Change interpreter state to interrupt mode */
/* 	defcode "INTERRUPT",9,F_COMPO+F_IMMED,INTERRUPT */
/* 	ldr     r0, =var_STATE */
/*     mov     r1, #2 */
/*     str     r1, [r0] */
/* 	NEXT */
	
/* @ HIDE ( -- ) hide a word */
/* 	defword "HIDE",4,,HIDE */
/* 	.4byte WORD		// Get the word (after HIDE). */
/* 	.4byte PAREN_FIND		// Look up in the dictionary. */
/* 	.4byte HIDDEN		// Set F_HIDDEN flag. */
/* 	.4byte EXIT		// Return. */

/* @ BRACKET_TICK ( -- ads) returns the codeword address of next read word */
/* @ only works in compile mode. Implementation is identical to LIT. */
/* 	defcode "[']",3,F_COMPO,BRACKET_TICK */
/* 	ldr r1, [fpc], #4 */
/* 	pushTOS */
/* 	mov tos, r1 */
/* 	NEXT */

/* @ BRANCH ( -- ) changes IP by offset which is found in the next codeword */
/* 	defcode "BRANCH",6,F_COMPO,BRANCH */
/*         ldr r1, [fpc] */
/*         add fpc, fpc, r1 */
/*         NEXT */

/* @ 0BRANCH ( p -- ) branch if the top of the stack is zero */
/* 	defcode "0BRANCH",7,F_COMPO,ZBRANCH */
/*     cmp tos, #0              @ if the top of the stack is zero */
/* 	popTOS */
/*     beq BRANCH         @ then branch */
/*     add fpc, fpc, #4          @ else, skip the offset */
/*     NEXT */


	
/* @ INTERPRET, reads a word from stdin and executes or compiles it */
/* 	defcode "INTERPRET",9,,INTERPRET */
/*     @ No need to backup callee save registers here, since */
/*     @ we are the top level routine */
/*         mov r3, #0                      @ interpret_is_lit = 0 */

/* 		ldr r0, = var_FIFO_put */
/* 		ldr r0, [r0]			@ top FIFO  */
/* 		ldr r1, = var_FIFO_get       */
/* 		ldr r1, [r1]			@ currkey */
/* 		cmp r0, r1 */
/* 		beq PAUSE */
	
/*         bl _WORD                        @ read a word from stdin */
/*         mov r4, r0                      @ store it in r4,r5 */
/*         mov r5, r1 */

/*         bl _FIND                        @ find its dictionary entry */
/*         cmp r0, #0                      @ if not found go to 1 */
/*         beq 1f */

/*     @ Here the entry is found */
/*         ldrb r6, [r0, #4]               @ read length and flags field */
/*         bl _TCFA                        @ find code field address */
/*     	tst r6, #F_IMMED                @ if the word is immediate	 */
/* 		beq 2f                            @ otherwise, branch to 2 */
/* 		tst r6, #F_COMPO		@ compile only? */
/* 	    bxeq r0                          @ (execute) */
/* 		ldr r1, =var_STATE              @ Are we compiling or executing ? */
/*         ldr r1, [r1] */
/*         cmp r1, #0 */
/* 		beq 7f */
/*         bxne r0                          @ (execute) */

/* 1:  @ Not found in dictionary */
/*         mov r3, #1                      @ interpret_is_lit = 1 */
/*         mov r0, r4                      @ restore word */
/*         mov r1, r5 */
/*         bl _NUMBER                      @ convert it to number */
/*         cmp r1, #0                      @ if errors were found */
/*         bne 6f                          @ then fail */

/*     @ it's a literal */
/*         mov r6, r0                      @ keep the parsed number if r6 */
/*         ldr r0, =LIT                    @ we will compile a LIT codeword */

/* 2:  @ Compiling or Executing */
/*         ldr r1, =var_STATE              @ Are we compiling or executing ? */
/*         ldr r1, [r1] */
/*         cmp r1, #0 */
/*         beq 4f                          @ Go to 4 if in interpret mode */
		
/*     @ Here in compile mode */

/*         bl _COMMA                       @ Call comma to compile the codeword */
/*         cmp r3,#1                       @ If it's a literal, we have to compile */
/*         moveq r0,r6                     @ the integer ... */
/*         bleq _COMMA                     @ .. too */
/*         NEXT */

/* 4:  @ Executing */
/*         cmp r3,#1                       @ if it's a literal, branch to 5 */
/*         beq 5f */

/* 		tst r6, #F_COMPO		@ compile only? */
/* 		bne 7f */
/*                                         @ not a literal, execute now */
/*         @@ ldr r0, [r0] */
/* 								@ (it's important here that */
/* 		bx r0                           @  IP address in r0, since DOCOL */
/*                                         @  assummes it) */

/* 5:  @ Push literal on the stack */
/* 	pushTOS */
/*         mov tos, r6 */
/*         NEXT */

/* 6:  @ Parse error */
/*         ldr r1, =errmsg */
/*         mov r2, #(errmsgend-errmsg) */
/* 	sendS */
	
/*         mov r1, r4 */
/*         mov r2, r5 */
/* 	sendS */
	
/*         ldr r1, =errmsg2 */
/*         mov r2, #(errmsg2end-errmsg2) */
/* 	sendS */
/*         NEXT */


/* 7:	@ compile only word */
/* 	 ldr r1, =errmsg3 */
/*      mov r2, #(errmsg3end-errmsg3) */
/* 	sendS */
	
/*         mov r1, r4 */
/*         mov r2, r5 */
/* 	sendS */
	
/*         ldr r1, =errmsg2 */
/*         mov r2, #(errmsg2end-errmsg2) */
/* 	sendS */
/*         NEXT */
	
/*         .section .rodata */
/* errmsg: .ascii "NOT RECOGNIZED<" */
/* errmsgend: */

/* errmsg2: .ascii ">\n" */
/* errmsg2end: */

/* errmsg3: .ascii "COMPILATION ONLY, USE IN DEFINITION<" */
/* errmsg3end: */

	

/* @ EXECUTE ( xt -- ) jump to the address on the stack */
/* 	defcode "EXECUTE",7,,EXECUTE */
/*     ldr r1, [tos] */
/* 	popTOS */
/*     bx r1 */
	



/* @@@ latest should be defword */
/* 	@ QUIT ( -- ) the first word to be executed */
/* 	defword "QUIT", 4,, QUIT */
/*     .4byte RZ, FETCH, RSPSTORE       @ Set up return stack */
/*     .4byte INTERPRET          @ Interpret a word */
/*     .4byte BRANCH,-8          @ loop */

/* 	.set RETURN_STACK_SIZE,512 */
/* 	.bss */
/* /\* FORTH return stack. *\/ */
/* 	.align	2 */
/* return_stack: */
/* 	.space RETURN_STACK_SIZE */
/* return_stack_top:		// Initial top of return stack. */
/* 	.align */
/* 	.ltorg */
/* 	.end */
/* /\* END OF jonesforth.S *\/	 */
