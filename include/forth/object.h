#ifndef OBJECT_H
#define OBJECT_H

#include <setjmp.h> /* jmp_buf, setjmp, longjmp */
#include <stdarg.h>
#include <stdint.h>
#include <string.h>

// /*
// 	The built-in variables are:

extern jmp_buf env;
extern uint8_t state;  // false execute, true compiling

#define F_EXE 0x01U
#define F_CMP_FLASH 0x02U
#define FORTH_IS_EXE_STATE ((state & F_EXE) != 0)           //  exe
#define FORTH_IS_CMP_STATE ((state & F_EXE) == 0)           //  exe
#define FORTH_IS_CMP_TO_FLASH ((state & F_CMP_FLASH) != 0)  //  exe
#define FORTH_IS_CMP_TO_RAM ((state & F_CMP_FLASH) == 0)    //  exe

extern void *here;
extern void *data_ptr;

typedef intptr_t ForthData;
typedef int32_t ForthFixNum;
typedef int64_t ForthBigNum;
typedef char ForthCharacter;
typedef size_t ForthIndex;

#define FORTH_IS_FIXNUM_VAL(x) (x <= INT32_MAX && x >= INT_LEAST32_MAX)
#define FORTH_IS_BIGNUM_VAL(x) (x <= INT64_MAX && x >= INT_LEAST64_MAX)

/*
        Implementation types.
*/
typedef enum {
  kNull = 0,
  kList = 1,
  kFixNum = 2, /* immediate fixnum */
  kBigNum = 3,
  kSingleFloat,
  kDoubleFloat,
  kLongDoubleFloat,
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

#define FORTH_TYPE_MASK(t) ((ForthFixNum)(t)&kFree)
#define FORTH_FLAG_MASK(t) ((ForthFixNum)(t) & !kFree)
#define FORTH_IS_IMMEDIATE(t) (FORTH_TYPE_MASK(t) <= kStructure)
#define FORTH_IS_LIST(t) (FORTH_TYPE_MASK(t) == t_list)
#define FORTH_IS_CONS(t) FORTH_LISTP(t)
#define FORTH_IS_CMPO(t) ((FORTH_FLAG_MASK(t) & kCompileOnly) != 0)
#define FORTH_IS_FLASH(t) ((FORTH_FLAG_MASK(t) & kFlash) != 0)
#define FORTH_IS_CODE(t) \
  ((FORTH_TYPE_MASK(t) >= kByteCode) && (FORTH_TYPE_MASK(t) <= kCodeBlock))

typedef struct {
  ForthType type;
  ForthData data;
} ForthObject;

typedef ForthObject ForthCell;
typedef void (*ForthFuncPtr)(void);
/* typedef ForthFuncPtr[]; */

typedef struct {
  ForthIndex size;
  ForthObject *word;
} ForthVector;

/* typedef struct { */
/*   ForthObject *stack; /\*  Is this relative to the lisp stack?  *\/ */
/*   ForthObject *base;  /\*  Start of frame  *\/ */
/*   cl_index size;    /\*  Number of arguments  *\/ */
/*   struct cl_env_struct *env; */
/* } ForthStackFrame; */

typedef struct {
  ForthObject car; /*  car  */
  ForthObject cdr; /*  cdr  */
} ForthCons;

ForthData ForthCreateData(ForthType t);
ForthObject ForthCreateObject(ForthType t);
ForthObject ForthCreateCons(ForthObject a, ForthObject b);
ForthObject ForthCreateNull();
#define FORTH_CONS_CAR(x) (((ForthCons *)x)->car)
#define FORTH_CONS_CDR(x) (((ForthCons *)x)->cdr)
#define CONS(a, d) ForthCreateCons((a), (d))
#define ACONS(a, b, c) ForthCreateCons(ForthCreateCons((a), (b)), (c))
#define FORTH_FIXNUM(x) ((ForthFixNum)(x))
#define FORTH_BIGNUM(x) ((ForthBigNum)(*x))
#define FORTH_SFLOAT(x) ((float)(*x))
#define FORTH_DFLOAT(x) ((double)(*x))
#define FORTH_LDFLOAT(x) ((long double)(*x))
#define FORTH_CFUN(x) ((ForthFuncPtr)(*x))

static inline ForthObject ForthCar(ForthObject x) {
  if (x.data == NULL) return x;
  x = FORTH_CONS_CAR(x.data);
  return x;
}

static inline ForthObject ForthCdr(ForthObject x) {
  if (x.data == NULL) return x;
  x = FORTH_CONS_CDR(x);
  return x;
}

void execute() {
  ForthType t = tos.type;
  if (FORTH_IS_IMMEDIATE(t)) {
    tos = tos.data;
  } else {
    switch (FORTH_TYPE_MASK(t)) {
      case kCFun: {
        (*(ForthFuncPtr)(tos.data))();
        break;
      }
      case kByteCode: {
        static ForthVector *x;
        static uint8_t i;
        x = (ForthVector *)(tos.data);
        PopTOS();
        for (i = 0; i < x->size; i++) {
          execute(x->word);
        }
        break;
      }
      default:
        ForthError("CANNOT EXECUTE WORD", itoa(tos.data, 16));
        break;
    }
  }
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

#endif /* OBJECT_H */
