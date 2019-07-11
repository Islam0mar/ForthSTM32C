#include <math.h>
#include <setjmp.h> /* jmp_buf, setjmp, longjmp */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "global.h"
#define FORTH_DEFINE_PRIMITIVES
#include "macros.h"

// // registers
// // register int *foo asm ("r12");
// extern uint32_t stack_top;  // top of the stack element
// extern uint32_t stack_index;  // parameter stack index
// extern uint32_t rstack_index;  // return stack index
// jmp_buf env;
// int val = 0;
// setjmp(env);
// // size_t PSP;    // parameter stack index
// // size_t RSP;    // return stack index
// extern uint32_t stack[MAXSTACK];
// extern uint32_t rstack[MAXRSTACK];
// defconst "SR0",2,,RZ,return_stack_top

/*
        QUIT AND INTERPRET
   ----------------------------------------------------------------------

        QUIT is the first FORTH function called, almost immediately after the
   FORTH system "boots". As explained before, QUIT doesn't "quit" anything.  It
   does some initialisation (in particular it clears the return stack) and it
   calls INTERPRET in a loop to interpret commands.  The reason it is called
   QUIT is because you can call it from your own FORTH words in order to "quit"
   your program and start again at the user prompt.

        INTERPRET is the FORTH interpreter ("toploop", "toplevel" or "REPL"
   might be a more accurate description -- see:
   http://en.wikipedia.org/wiki/REPL).
*/
DEFCODE(NULL, "QUIT", 0, quit,
        "Quit your program and start again at the user prompt",
        { longjmp(env, 0); });

DEFCODE(NULL, "KEY", 0, key, "( -- c ) Receive one character", {
  PushTOS();
  tos = TIBReadChar();
});

DEFCODE(NULL, "KEY?", 0, is_key, "( -- 0|1 ) Receive one character", {
  PushTOS();
  tos = (TIBEmpty()) ? 0 : 1;
});

DEFCODE(NULL, "WORD", 0, word, "( -- addr length ) reads next word from buffer",
        {
          static uint8_t i;
          for (i = 0;;) {
            pad[i] = TIBReadChar();
            switch (pad[i]) {
              case ' ': {
                break;
              }
              case '\\': {
                do {
                  pad[i] = TIBReadChar();
                } while (pad[i] != '\n');
                break;
              }
              case '(': {
                do {
                  pad[i] = TIBReadChar();
                } while (pad[i] != ')');
                break;
              }
              default: {
                do {
                  ++i;
                  if (i >= PAD_SIZE) {
                    ForthError("PAD size over flow");
                  }
                  pad[i] = TIBReadChar();
                } while (pad[i] != ' ');
                pad[i] = '\0';
                break;
              }
            }
          }
          PushTOS();
          PushPSP(pad);
          tos = i;
        });

DEFCODE(NULL, "(FIND)", 0, paren_find, "( addr length -- dictionary_address )",
        {
          PopTOS();
          tos = findDictionaryItem(GetDictPtr(), tos);
        });

DEFCODE(NULL, ">CFA", 0, tcfa, "( dictionary_address -- executable_address )",
        { tos = tos->ptr; });

DEFCODE(NULL, ">DFA", 0, tdfa, "( dictionary_address -- data_field_address )",
        { os = tos->ptr; });

// @ LIT is used to compile literals in forth word.
// @ When LIT is executed it pushes the literal (which is the next codeword)
// @ into the stack and skips it (since the literal is not executable).
DEFCODE(NULL, "LIT", 0, lit, "compile literals in forth word",
        {
          word();
          paren_find();
          // word not found in dict
          if(tos == NULL) {
            if(EXECUTE_STATE) {// exec
              pushTOS();
              tos = StrToInt();
            } else{ // compile mode

            }
          }
//     defcode "LIT",3,F_COMPO,LIT
// 	pushTOS
//     ldr tos, [fpc], #4
// NEXT
DEFCODE(NULL, ",", 0, comma,
        "( n -- ) writes the top element from the stack at DP", {
          if (FORTH_IS_EXE_STATE) {
            
          } else {
            // HA
            uint8_t len = 1 + GetDictPtr()->head.entry.length;
            GetDictPtr()->head.ptr =
                relloc(GetDictPtr()->head.ptr, len * sizeof(FuncPtr));
            GetDictPtr()->head.entry.length++;
            GetDictPtr()->head.ptr[len - 1] = tos;
            PopTOS();
          }
          /* here */
        });

/*       This interpreter is pretty simple, but remember that in FORTH you can
always override it later with a more powerful one!
*/
DEFCODE(NULL, "INTERPRET", 0, interpret, "Interpret inputs", {
  word();
  paren_find();
  // word not found in dict
  if (tos == NULL) {
    if (EXECUTE_STATE) {  // exec
      tos = StrToForthObj();
    } else {  // compile mode
      tos = StrToForthObj();;
      comma();
      tos = StrToInt();
      comma();
    }
  }

  if ((tos->entry.flags & F_IMMED) != 0) {
    if ((tos->entry.flags & F_COMPO) != 0 && !STATE) {
      char err[PAD_SIZE + 27] = "COMPILATION ONLY WORD, <";
      strcat(err, pad);
      strcat(err, ">.");
      ForthError(err);
    } else if ((tos->entry.flags & F_CODE) != 0) {
      (*tos->ptr)();
    } else {
      static uint8_t i;
      for (i = 0; i < tos->entry.length; i++) {
        (tos->entry.ptr[i])();
      }
    }

  } else if ((tos->entry.flags & F_COMPO) != 0 && !STATE) {
    char err[PAD_SIZE + 26] = "COMPILATION ONLY WORD <";
    strcat(err, pad);
    strcat(err, ">.");
    ForthError(err);
  } else if ((tos->entry.flags & F_COMPO) != 0 || !STATE) {
    if ((tos->entry.flags & F_CODE) != 0) {
      (*tos->ptr)();
    } else {
      static uint8_t i;
      for (i = 0; i < tos->entry.length; i++) {
        (tos->entry.ptr[i])();
      }
    }
  } else if ((tos->entry.flags & F_COMPO) != 0) {
    if (STATE) {
    }
  }
})

/* 		ldr r1, =var_STATE              @ Are we compiling or executing
 * ?
 */
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

/*         bl _COMMA                       @ Call comma to compile the codeword
 */
/*         cmp r3,#1                       @ If it's a literal, we have to
 * compile */
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
/* 								@ (it's important here
 * that
 */
/* 		bx r0                           @  IP address in r0, since DOCOL
 */
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

/* @ CHAR ( -- c ) put the ASCII code of the first character of the next word */
/* @ on the stack */
/* 	defcode "CHAR",4,,CHAR */
/*         bl _WORD */
/*         ldrb r1, [r0] */
/* 	pushTOS */
/*         mov tos, r1 */
/*         NEXT */

/* @ EXECUTE ( xt -- ) jump to the address on the stack */
/* 	defcode "EXECUTE",7,,EXECUTE */
/*     ldr r1, [tos] */
/* 	popTOS */
/* bx r1 */

/*         }); */

// //   ?RX		( -- c T | F )
// //		Return input character and true, or a false if no input.

// void QRX(void) {}

// //   TX!		( c -- )
// //		Send character c to the output device.
// void TXSTO(void) {}

// //   !IO		( -- )
// //		Initialize the serial I/O devices.
// void STOIO(void) {}

// //// The kernel

// //   doLIT	( -- w )
// //		Push an inline literal.
// void DOLIT(void) {}

// //   doLIST	( a -- )
// //		Process colon list.
// void DOLST(void)

//     //   EXIT	( -- )
//     //		Terminate a colon definition.

//     void EXIT

//     //   EXECUTE	( ca -- )
//     //		Execute the word at ca.

//     // void EXECU

//     //   next	( -- )
//     //		Run time code for the single index loop.
//     //		: next ( -- ) \ hilevel model
//     //		  r> r> dup if 1 - >r @ >r exit then drop cell+ >r //

//     void DONXT

//     //   ?branch	( f -- )
//     //		Branch if flag is zero.

//     void QBRAN

//     //   branch	( -- )
//     //		Branch to an inline address.

//     void BRAN

//     //   !		( w a -- )
//     //		Pop the data stack to memory.

//     void STORE

//     //   @		( a -- w )
//     //		Push memory location to the data stack.

//     void AT

//     //   C!		( c b -- )
//     //		Pop the data stack to byte memory.

//     void CSTOR

//     //   C@		( b -- c )
//     //		Push byte memory location to the data stack.

//     void CAT

//     //   RP@		( -- a )
//     //		Push the current RP to the data stack.

//     void RPAT

//     //   RP!		( a -- )
//     //		Set the return stack pointer.

//     void RPSTO

//     //   R>		( -- w )
//     //		Pop the return stack to the data stack.

//     void RFROM

//     //   R@		( -- w )
//     //		Copy top of return stack to the data stack.

//     void RAT

//     //   >R		( w -- )
//     //		Push the data stack to the return stack.

//     void TOR

//     //   SP@		( -- a )
//     //		Push the current data stack pointer.

//     void SPAT

//     //   SP!		( a -- )
//     //		Set the data stack pointer.

//     void SPSTO

//     //   DROP	( w -- )
//     //		Discard top stack item.

//     void DROP

//     //   DUP		( w -- w w )
//     //		Duplicate the top stack item.

//     void DUPP

//     //   SWAP	( w1 w2 -- w2 w1 )
//     //		Exchange top two stack items.

//     void SWAP

//     //   OVER	( w1 w2 -- w1 w2 w1 )
//     //		Copy second stack item to top.

//     void OVER

//     //   0<		( n -- t )
//     //		Return true if n is negative.

//     void ZLESS

//     //   AND		( w w -- w )
//     //		Bitwise AND.

//     void ANDD

//     //   OR		( w w -- w )
//     //		Bitwise inclusive OR.

//     void ORR

//     //   XOR		( w w -- w )
//     //		Bitwise exclusive OR.

//     void XORR

//     //   UM+		( w w -- w cy )
//     //		Add two numbers, return the sum and carry flag.

//     void UPLUS
