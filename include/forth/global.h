/**
 *   \file global.h
 *   \brief A Documented file.
 *
 *  copyright MIT
 *
 */

#ifndef GLOBAL_H
#define GLOBAL_H

#include <ctype.h>
#include <errno.h>
#include <setjmp.h> /* jmp_buf, setjmp, longjmp */
#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* The built-in variables are: */
extern jmp_buf env;
extern uint8_t state;  // execute, compiling, flash, RAM
extern void *here;
extern const uint32_t flash_end;

#define BITMASK_SET(x, f) ((x) |= (f))
#define BITMASK_CLEAR(x, f) ((x) &= (~(f)))
#define BITMASK_CHECK_CLEAR(x, f) (((x) &= (f)) == 0)
#define BITMASK_CHECK_SET(x, f) (((x) &= (f)) != 0)
#define F_EXE 0x01U
#define F_CMP_FLASH 0x02U
#define FORTH_IS_EXE_STATE BITMASK_CHECK_SET(state, F_EXE)           //  exe
#define FORTH_IS_CMP_STATE BITMASK_CHECK_CLEAR(state, F_EXE)         //  exe
#define FORTH_IS_CMP_TO_FLASH BITMASK_CHECK_SET(state, F_CMP_FLASH)  //  exe
#define FORTH_IS_CMP_TO_RAM BITMASK_CHECK_CLEAR(state, F_CMP_FLASH)  //  exe
#define FORTH_CMP_TO_FLASH() BITMASK_SET(state, F_CMP_FLASH)         //  exe
#define FORTH_CMP_TO_RAM() BITMASK_CLEAR(state, F_CMP_FLASH)         //  exe
#define FORTH_EXE_STATE() BITMASK_SET(state, F_EXE)                  //  exe
#define FORTH_CMP_STATE() BITMASK_CLEAR(state, F_EXE)                //  exe

typedef intptr_t ForthData;
typedef int32_t ForthFixNum;
typedef int64_t ForthBigNum;
typedef char ForthCharacter;
typedef size_t ForthIndex;
typedef void (*ForthFuncPtr)(void);

/*
        Implementation types.
*/
typedef enum {
  kCons = 0,
  kFixNum = 2, /* immediate fixnum */
  kBigNum = 3,
  kSingleFloat,
  kDoubleFloat,
  kLongDoubleFloat,
  kVector,
  kPointer,
  kTypeMask = 31,
  kExecutable = 1 << 4,  /*  executable code   */
  kFree = 1 << 5,        /*  TODO: free object for GC   */
  kCompileOnly = 1 << 6, /* compile only */
  kFlash = 1 << 7,       /* flash */
} ForthType;

typedef struct {
  ForthType type;
  ForthData data;
} ForthObject;

typedef ForthObject ForthCell;

typedef struct {
  ForthIndex size;
  ForthObject *word;
} ForthVector;

typedef struct {
  ForthObject car; /*  car  */
  ForthObject cdr; /*  cdr  */
} ForthCons;


#endif /* GLOBAL_H */
