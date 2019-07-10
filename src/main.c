/*

 * @CreateTime: Jul 20, 2017 4:21 PM
 * @Author: Islam Omar
 * @Contact: io1131@fayoum.edu.eg
 * @Last Modified By: Islam Omar
 * @Last Modified Time: Jul 20, 2017 4:21 PM
 * @Description: Modify Here, Please
 */

#include "hal/bsp.h"
#include "forth/dictionary.h"
#include "forth/words.h"


int main(void) {
  Init();
  /* DictionaryEntry code; */
  /* loadDictionaryEntry(code, "and", 3); */
  /* code.IP[0] = &xx; */
  /* (*code.IP[0])(); */
  /* NEXT(); */
  jmp_buf env;
  setjmp(env);

  if(terminal_buffer_get_index == terminal_buffer_insert_index){
    /* Multi tasking */
    Pause();
  }
  
	
        bl _WORD                        @ read a word from stdin
        mov r4, r0                      @ store it in r4,r5
        mov r5, r1

        bl _FIND                        @ find its dictionary entry
        cmp r0, #0                      @ if not found go to 1
        beq 1f

    @ Here the entry is found
        ldrb r6, [r0, #4]               @ read length and flags field
        bl _TCFA                        @ find code field address
    	tst r6, #F_IMMED                @ if the word is immediate	
		beq 2f                            @ otherwise, branch to 2
		tst r6, #F_COMPO		@ compile only?
	    bxeq r0                          @ (execute)
		ldr r1, =var_STATE              @ Are we compiling or executing ?
        ldr r1, [r1]
        cmp r1, #0
		beq 7f
        bxne r0                          @ (execute)

1:  @ Not found in dictionary
        mov r3, #1                      @ interpret_is_lit = 1
        mov r0, r4                      @ restore word
        mov r1, r5
        bl _NUMBER                      @ convert it to number
        cmp r1, #0                      @ if errors were found
        bne 6f                          @ then fail

    @ it's a literal
        mov r6, r0                      @ keep the parsed number if r6
        ldr r0, =LIT                    @ we will compile a LIT codeword

2:  @ Compiling or Executing
        ldr r1, =var_STATE              @ Are we compiling or executing ?
        ldr r1, [r1]
        cmp r1, #0
        beq 4f                          @ Go to 4 if in interpret mode
		
    @ Here in compile mode

        bl _COMMA                       @ Call comma to compile the codeword
        cmp r3,#1                       @ If it's a literal, we have to compile
        moveq r0,r6                     @ the integer ...
        bleq _COMMA                     @ .. too
        NEXT

4:  @ Executing
        cmp r3,#1                       @ if it's a literal, branch to 5
        beq 5f

		tst r6, #F_COMPO		@ compile only?
		bne 7f
                                        @ not a literal, execute now
        @@ ldr r0, [r0]
								@ (it's important here that
		bx r0                           @  IP address in r0, since DOCOL
                                        @  assummes it)

5:  @ Push literal on the stack
	pushTOS
        mov tos, r6
        NEXT

6:  @ Parse error
        ldr r1, =errmsg
        mov r2, #(errmsgend-errmsg)
	sendS
	
        mov r1, r4
        mov r2, r5
	sendS
	
        ldr r1, =errmsg2
        mov r2, #(errmsg2end-errmsg2)
	sendS
        NEXT


7:	@ compile only word
	 ldr r1, =errmsg3
     mov r2, #(errmsg3end-errmsg3)
	sendS
	
        mov r1, r4
        mov r2, r5
	sendS
	
        ldr r1, =errmsg2
        mov r2, #(errmsg2end-errmsg2)
	sendS
        NEXT
	
        .section .rodata
errmsg: .ascii "NOT RECOGNIZED<"
errmsgend:

errmsg2: .ascii ">\n"
errmsg2end:

errmsg3: .ascii "COMPILATION ONLY, USE IN DEFINITION<"
errmsg3end:

	
@ CHAR ( -- c ) put the ASCII code of the first character of the next word
@ on the stack
	defcode "CHAR",4,,CHAR
        bl _WORD
        ldrb r1, [r0]
	pushTOS
        mov tos, r1
        NEXT

@ EXECUTE ( xt -- ) jump to the address on the stack
	defcode "EXECUTE",7,,EXECUTE
    ldr r1, [tos]
	popTOS
    bx r1

  // enable fly chech mode instruction pointer

  return 0;
}

/*
int stackptr;
asm
{
    LDR r0, =stackptr  // put address of C variable stackptr in r0
    MOV r1, sp         // move value of sp to r1
    STR r1, [r0]       // put value of r1 in address contained in r0 (stackptr)
}*/
