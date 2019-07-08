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
/*
        This interpreter is pretty simple, but remember that in FORTH you can
   always override it later with a more powerful one!
 */
DEFCODE(NULL, "INTERPRET", 0, interpret, "Interpret inputs",
        {
          

        });

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
