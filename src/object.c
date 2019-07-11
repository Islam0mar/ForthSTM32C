/**
 *   \file object.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */

#include "forth/object.h"

static inline void *ForthAlloc(ForthIndex s) {
  static void *temp;
  temp = malloc(s);
  if (temp == NULL) {
    ForthError("Allocation failed!");
  }
}

ForthData ForthCreateData(ForthType t) {
  static ForthData data = NULL;
  switch (FORTH_TYPE_MASK(t)) {
    case kStart: {
      data = NULL;
      break;
    }
    case kList: {
      data = ForthAlloc(sizeof(ForthCons));
      break;
    }
    case kFixNum: {
      /* data = -1; */
      break;
    }
    case kBigNum: {
      data = ForthAlloc(sizeof(int64_t));
      break;
    }
    case kSingleFloat: {
      data = ForthAlloc(sizeof(float));
      break;
    }
    case kDoubleFloat: {
      data = ForthAlloc(sizeof(double));
      break;
    }
    case kLongDoubleFloat: {
      data = ForthAlloc(sizeof(long double));
      break;
    }
    case kVector: {
      data = ForthAlloc(sizeof(ForthVector));
      break;
    }
    case kString: {
      data = ForthAlloc(sizeof(ForthVector));
      break;
    }
    case kInstance: {
      data = ForthAlloc(sizeof(ForthVector));
      break;
    }
    case kByteCode: {
      data = ForthAlloc(sizeof(ForthVector));
      break;
    }
    case kCFun: {
      /* data = &d; */
      data = ForthAlloc(sizeof(ForthFuncPtr));
      break;
    }
    case kCodeBlock: {
      data = ForthAlloc(sizeof(ForthFuncPtr));
      /* data = int(*f)(); */
      /* f = (int (*)()) & RawCode; */
      /* (int)(*f)(); */
      break;
    }
    case kMemBlock: {
      data = ForthAlloc(sizeof(ForthFuncPtr));
      /* data = int(*f)(); */
      /* f = (int (*)()) & RawCode; */
      /* (int)(*f)(); */
      break;
    }
    /* case kFrame: { */
    /*   /\* data = ForthAlloc(size * sizeof(ForthStackFrame)) *\/ */
    /*   break; */
    /* } */
    default:
      ForthError("Unknown type");
      break;
  }
  return data;
}

ForthObject ForthCreateObject(ForthType t) {
  static ForthObject obj;
  if (FORTH_IS_CMP_TO_RAM) {
    obj = ForthAlloc(sizeof(_ForthObject));
    obj->type = t;
    obj->data = CreateForthData(t);
  } else {
  }
  return ob;
}

ForthObject ForthCons(ForthObject a, ForthObject b) {
  static ForthObject obj = ForthCreateObject(kList);
  obj->data->car = a;
  obj->data->cdr = b;
  return obj;
}

ForthObject ForthNull() {
  static ForthObject obj = ForthCreateObject(kStart);
  return obj;
}

