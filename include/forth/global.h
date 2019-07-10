#ifndef GLOBAL_H
#define GLOBAL_H

#include <setjmp.h> /* jmp_buf, setjmp, longjmp */
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

typedef void (*FuncPtr)(void);

// /*
// 	The built-in variables are:

// 	STATE		Is the interpreter executing code (0) or compiling a word (non-zero)?
// 	LATEST		Points to the latest (most recently defined) word in the dictionary.
// 	DP		Points to the next free byte of memory.  When compiling, compiled words go here.
// 	S0		Stores the address of the top of the parameter stack.
// 	BASE		The current base for printing and reading numbers.

// 	*/
// 	/* RAM vector table*/

// 	defvar "STATE",5,,STATE
// 	defvar "DP",2,,DP
// 	defvar "FLASH",5,,FLASH		// latest flash position
// 	defvar "RAM",3,,RAM			// latest ram position 
// 	defvar "LATEST",6,,LATEST,name_QUIT @ latest defined word
// 	defvar "F_LATEST",8,,F_LATEST,name_QUIT @ latest defined word FLASH
// 	defvar "BASE",4,,BASE,10
// 	defvar "S0",2,,SZ,__stack_end__
// 	defvar "R0",2,,RZ,return_stack_top
// 	defvar "BOOT",4,,BOOT,QUIT
// clang-format on

extern jmp_buf env;
extern uint8_t state; // false excyte, true compiling
#define F_EXE 0x01U
#define F_CMP_FLASH 0x02U
#define IS_EXE   ((state&F_EXE)!=0)  //  exe
#define IS_CMP   ((state&F_EXE)==0)  //  exe
#define IS_CMP_FLASH   ((state&F_CMP_FLASH)!=0)  //  exe
#define IS_CMP_RAM   ((state&F_CMP_FLASH)==0)  //  exe
extern void* here;
extern void* data_ptr;
// registers
// register int *foo asm ("r12");
// extern uint32_t TOS;  // top of the stack element
// extern uint32_t PSP;  // parameter stack index
// extern uint32_t RSP;  // return stack index
// size_t PSP;    // parameter stack index
// size_t RSP;    // return stack index
// extern uint32_t PS[MAXSTACK];
// extern uint32_t RS[MAXRSTACK];
// extern FuncPtr *IP;  // instruction pointer
// extern FuncPtr W;    // working register

#endif /* GLOBAL_H */
