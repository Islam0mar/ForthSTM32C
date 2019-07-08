#ifndef GLOBAL_H
#define GLOBAL_H

#include <setjmp.h> /* jmp_buf, setjmp, longjmp */

typedef void (*FuncPtr)(void);

// clang-format off
/*
        Implementation types.
*/
extern const uint8_t F_IMMED;   // immediate
extern const uint8_t F_COMPO;   // compile only
extern const uint8_t F_HIDDEN;  // hidden
extern const uint8_t F_FLASH;   // flash
// clang-format on

extern jmp_buf env;

#define MAXSTACK 512
#define MAXRSTACK 256

// registers
// register int *foo asm ("r12");
extern uint32_t TOS;  // top of the stack element
extern uint32_t PSP;  // parameter stack index
extern uint32_t RSP;  // return stack index
// size_t PSP;    // parameter stack index
// size_t RSP;    // return stack index
extern uint32_t PS[MAXSTACK];
extern uint32_t RS[MAXRSTACK];
extern FuncPtr *IP;  // instruction pointer
extern FuncPtr W;    // working register

#endif /* GLOBAL_H */
