#ifndef GLOBAL_H
#define GLOBAL_H

#include <setjmp.h> /* jmp_buf, setjmp, longjmp */
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

// /*
// 	The built-in variables are:

// 	STATE		Is the interpreter executing code (0) or compiling a
// word (non-zero)?
// 	LATEST		Points to the latest (most recently defined) word in the
// dictionary.
// 	DP		Points to the next free byte of memory.  When compiling,
// compiled words go here. 	S0		Stores the address of the top of
// the parameter stack. 	BASE		The current base for printing
// and reading numbers.

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
extern uint8_t state;  // false execute, true compiling

#define F_EXE 0x01U
#define F_CMP_FLASH 0x02U
#define FORTH_IS_EXE_STATE ((state & F_EXE) != 0)              //  exe
#define FORTH_IS_CMP_STATE ((state & F_EXE) == 0)              //  exe
#define FORTH_IS_CMP_TO_FLASH ((state & F_CMP_FLASH) != 0)  //  exe
#define FORTH_IS_CMP_TO_RAM ((state & F_CMP_FLASH) == 0)    //  exe

extern void *here;
extern void *data_ptr;

/* struct { */
/*   enum { is_int, is_float, is_char } type; */
/*   union { */
/*     int ival; */
/*     float fval; */
/*     char cval; */
/*   } val; */
/* } my_array[10]; */
/* #define F_IMMED 0x80U   // immediate */
/* #define F_COMPO 0x40U   // compile only */
/* #define F_HIDDEN 0x20U  // hidden */
/* #define F_FLASH 0x10U   // flash */
/* #define F_FUNC 0x01U    // contains one function */

typedef uint32_t ForthCell;
typedef ForthCell ForthFixNum;
typedef char ForthCharacter;
typedef size_t ForthIndex;

/*
        Implementation types.
*/
typedef enum {
  kStart = 0,
  kList = 1,
  kFixNum = 2, /* immediate fixnum */
  kBigNum = 3,
  kSingleFloat,
  kDoubleFloat,
  kLongFloat,
  kArray,
  kString,
  /* kPointer, */
  kInstance, /* OOP */
  kStructure = kInstance,
  /* kSemaphore,  /\* multi tasking *\/ */
  kByteCode,  /* derived words => array of forth objects*/
  kCFun,      /* primitive words */
  kCodeBlock, /* asssembler */
  kMemBlock,  /* malloc mem */
  kFrame,
  kFree = 63,             /*  TODO: free object for GC   */
  kCompileOnly = 1 << 6,  // compile only
  kFlash = 1 << 7,        // flash
} ForthType;

#define FORTH_IMMEDIATE(t) ((ForthFixNum)(t)&kFree)
#define FORTH_FLAG(t) ((ForthFixNum)(t) & !kFree)
#define FORTH_IS_IMMEDIATE(t) (FORTH_IMMEDIATE(t) <= kStructure)
#define FORTH_IS_LIST(t) (FORTH_IMMEDIATE(t) == t_list)
#define FORTH_IS_CONS(t) FORTH_LISTP(t)
#define FORTH_IS_CMPO(t) ((FORTH_FLAG(t) & kCompileOnly) != 0)
#define FORTH_IS_FLASH(t) ((FORTH_FLAG(t) & kFlash) != 0)
#define FORTH_IS_CODE(t) \
  ((FORTH_IMMEDIATE(t) >= kByteCode) && (FORTH_IMMEDIATE(t) <= kCodeBlock))

typedef struct {
  ForthType type;
  intptr_t data;
} _ForthObject;

typedef _ForthObject *ForthObject;
typedef void (*ForthFuncPtr)(void);
typedef ForthFuncPtr[];

typedef struct {
  ForthIndex size;   
  ForthObject *words;
} ForthByteCode;

/* typedef struct { */
/*   cl_object *stack; /\*  Is this relative to the lisp stack?  *\/ */
/*   cl_object *base;  /\*  Start of frame  *\/ */
/*   cl_index size;    /\*  Number of arguments  *\/ */
/*   struct cl_env_struct *env; */
/* } ForthStackFrame; */

typedef struct {
  cl_object car; /*  car  */
  cl_object cdr; /*  cdr  */
} ForthCons;

#define ECL_CONS_CAR(x) ((x)->cons.car)
#define ECL_CONS_CDR(x) ((x)->cons.cdr)
#define Null(x) ((x) == ECL_NIL)
#define CONS(a, d) ecl_cons((a), (d))
#define ACONS(a, b, c) ecl_cons(ecl_cons((a), (b)), (c))

ForthObject CreateForthObject(intptr_t data, ForthType t);

/* BEGIN-GENERATED (gen-cons-h) */

void execute(ForthObject o){
  ForthType t = tos->type;
  if(FORTH_IS_IMMEDIATE(t)){
    tos = tos->data;
  } else if(FORTH_IS_CODE(t)){
    tos = tos->data;
  }

  kFixNum = 2, /* immediate fixnum */
  kBigNum = 3,
  kSingleFloat,
  kDoubleFloat,
  kLongFloat,
  kArray,
  kString,
  /* kPointer, */
  kInstance, /* OOP */
  kStructure = kInstance,
  /* kSemaphore,  /\* multi tasking *\/ */
  kByteCode,  /* derived words => array of forth objects*/
  kCFun,      /* primitive words */
  kCodeBlock, /* asssembler */
  kMemBlock,  /* malloc mem */
  kFrame,
  kFree = 63,             /*  TODO: free object for GC   */
  kCompileOnly = 1 << 6,  // compile only
  kFlash = 1 << 7,        // flash
} ForthType;
}
#if ECL_CAN_INLINE
static ECL_INLINE cl_object _ecl_car(cl_object x) {
  if (Null(x)) return x;
  x = ECL_CONS_CAR(x);
  return x;
}

static ECL_INLINE cl_object _ecl_cdr(cl_object x) {
  if (Null(x)) return x;
  x = ECL_CONS_CDR(x);
  return x;
}

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
