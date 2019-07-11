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

static inline void *ForthRealloc(ForthData d, ForthIndex s) {
  static void *temp;
  temp = realloc(d, s);
  if (temp == NULL) {
    ForthError("Allocation failed!");
  }
}

ForthData ForthCreateData(ForthType t) {
  static ForthData data = NULL;
  switch (FORTH_TYPE_MASK(t)) {
    case kNull: {
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

ForthObject ForthCreateEmptyObject(ForthType t) {
  static ForthObject obj;
  if (FORTH_IS_CMP_TO_RAM) {
    obj = ForthAlloc(sizeof(_ForthObject));
    obj->type = t;
    obj->data = CreateForthData(t);
  } else {
  }
  return ob;
}

ForthObject ForthCreateCons(ForthObject a, ForthObject b) {
  static ForthObject obj = ForthCreateEmptyObject(kList);
  FORTH_CONS_CAR(x->data) = a;
  FORTH_CONS_CDR(x->data) = b;
  return obj;
}

ForthObject ForthCreateNull() {
  static ForthObject obj = ForthCreateEmptyObject(kNull);
  return obj;
}

ForthObject ForthCreateFixNum(ForthFixNum x) {
  ForthObject obj = ForthCreateEmptyObject(kFixNum);
  obj->data = x;
  return obj;
}

ForthObject ForthCreateBigNum(ForthBigNum x) {
  ForthObject obj = ForthCreateEmptyObject(kBigNum);
  *obj->data = x;
  return obj;
}

ForthObject ForthCreateSingleFloat(float x) {
  ForthObject obj = ForthCreateEmptyObject(kSingleFloat);
  *obj->data = x;
  return obj;
}

ForthObject ForthCreateDoubleFloat(double x) {
  ForthObject obj = ForthCreateEmptyObject(kDoubleFloat);
  *obj->data = x;
  return obj;
}

ForthObject ForthCreateLongDoubleFloat(long double x) {
  ForthObject obj = ForthCreateEmptyObject(kLongDoubleFloat);
  *obj->data = x;
  return obj;
}

ForthObject ForthCreateEmptyVector() {
  ForthObject obj = ForthCreateEmptyObject(kVector);
  ((ForthVector *)obj->data)->size = 0;
  ((ForthVector *)obj->data)->word = NULL;
  return obj;
}

ForthObject ForthCreateVector(ForthObject x) {
  ForthObject obj;
  obj = ForthCreateEmptyVector();
  ForthAddToVector(x, obj->data);
  return obj;
}

ForthObject ForthCreateCFun(ForthFuncPtr x) {
  ForthObject obj = ForthCreateEmptyObject(kCFun);
  *obj->data = x;
  return obj;
}

void ForthAddToVector(ForthObject x, ForthVector *v) {
  v->word = ForthRealloc(v->word, sizeof(v->word) + sizeof(x));
  v->word[size] = x;
  v->size++;
}

ForthObject ForthCreateObject(ForthData x, ForthType t) {
  static ForthObject obj = NULL;
  switch (FORTH_TYPE_MASK(t)) {
    case kNull: {
      obj = ForthCreateNull();
      break;
    }
    case kList: {
      obj = CONS((ForthObject)x, ForthCreateNull());
      break;
    }
    case kFixNum: {
      obj = ForthCreateFixNum(FORTH_FIXNUM(x));
      break;
    }
    case kBigNum: {
      obj = ForthCreateBigNum(FORTH_BIGNUM(x));
      break;
    }
    case kSingleFloat: {
      obj = ForthCreateSingleFloat(FORTH_SFLOAT(x));
      break;
    }
    case kDoubleFloat: {
      obj = ForthCreateDoubleFloat(FORTH_DFLOAT(x));
      break;
    }
    case kLongDoubleFloat: {
      obj = ForthCreateLongDoubleFloat(FORTH_LDFLOAT(x));
      break;
    }
    case kVector: {
      obj = ForthCreateVector((ForthObject)x);
      break;
    }
    case kString: {
      uint8_t i = 0;
      obj = ForthCreateEmptyVector();
      for (; x[i] != '\0'; i++) {
        ForthAddToVector(ForthCreateObject(x[i], kFixNum),
                         (ForthVector *)obj->data);
      }
      break;
    }
    /* case kInstance: { */
    /*   obj = ForthCreate(FORTH_); */
    /*   break; */
    /* } */
    case kByteCode: {
      obj = ForthCreateVector((ForthObject)x);
      break;
    }
    case kCFun: {
      /* data = &d; */
      obj = ForthCreateCFun(FORTH_CFUN(x));
      break;
    }
    /* case kCodeBlock: { */
    /*   obj = ForthCreate(FORTH_); */
    /*   /\* data = int(*f)(); *\/ */
    /*   /\* f = (int (*)()) & RawCode; *\/ */
    /*   /\* (int)(*f)(); *\/ */
    /*   break; */
    /* } */
    /* case kMemBlock: { */
    /*   obj = ForthCreate(FORTH_); */
    /*   /\* data = int(*f)(); *\/ */
    /*   /\* f = (int (*)()) & RawCode; *\/ */
    /*   /\* (int)(*f)(); *\/ */
    /*   break; */
    /* } */
      /* case kFrame: { */
      /* obj = ForthCreate(FORTH_); */
    /*   break; */
    /* } */
    default:
      ForthError("Unknown type");
      break;
  }
  return obj;
}
/* ForthData ForthCopyDataRecursive(ForthObject src, ForthObject dist) { */
/*   switch (FORTH_TYPE_MASK(src->t)) { */
/*     case kNull: { */
/*       src->data = NULL; */
/*       break; */
/*     } */
/*     case kList: { */
/*       static ForthObject x; */
/*       for (x = ForthCar(src); x->t != kNull; x = ForthCar(ForthCdr(x))) {
 */
/*         ForthCopyDataRecursive(x, x); */
/*       } */
/*       data = ForthRealloc(dist, sizeof(ForthCons)); */
/*       break; */
/*     } */
/*     case kFixNum: { */
/*       /\* data = -1; *\/ */
/*       break; */
/*     } */
/*     case kBigNum: { */
/*       data = ForthRealloc(dist, sizeof(int64_t)); */
/*       break; */
/*     } */
/*     case kSingleFloat: { */
/*       data = ForthRealloc(dist, sizeof(float)); */
/*       break; */
/*     } */
/*     case kDoubleFloat: { */
/*       data = ForthRealloc(dist, sizeof(double)); */
/*       break; */
/*     } */
/*     case kLongDoubleFloat: { */
/*       data = ForthRealloc(dist, sizeof(long double)); */
/*       break; */
/*     } */
/*     case kVector: { */
/*       data = ForthRealloc(dist, sizeof(ForthVector)); */
/*       break; */
/*     } */
/*     case kString: { */
/*       data = ForthRealloc(dist, sizeof(ForthVector)); */
/*       break; */
/*     } */
/*     case kInstance: { */
/*       data = ForthRealloc(dist, sizeof(ForthVector)); */
/*       break; */
/*     } */
/*     case kByteCode: { */
/*       data = ForthRealloc(dist, sizeof(ForthVector)); */
/*       break; */
/*     } */
/*     case kCFun: { */
/*       /\* data = &d; *\/ */
/*       data = ForthRealloc(dist, sizeof(ForthFuncPtr)); */
/*       break; */
/*     } */
/*     case kCodeBlock: { */
/*       data = ForthRealloc(dist, sizeof(ForthFuncPtr)); */
/*       /\* data = int(*f)(); *\/ */
/*       /\* f = (int (*)()) & RawCode; *\/ */
/*       /\* (int)(*f)(); *\/ */
/*       break; */
/*     } */
/*     case kMemBlock: { */
/*       data = ForthRealloc(dist, sizeof(ForthFuncPtr)); */
/*       /\* data = int(*f)(); *\/ */
/*       /\* f = (int (*)()) & RawCode; *\/ */
/*       /\* (int)(*f)(); *\/ */
/*       break; */
/*     } */
/*     /\* case kFrame: { *\/ */
/*     /\*   /\\* data = ForthRealloc(dist,size * sizeof(ForthStackFrame))
 * *\\/
 * *\/ */
/*     /\*   break; *\/ */
/*     /\* } *\/ */
/*     default: */
/*       ForthError("Unknown type"); */
/*       break; */
/*   } */
/*   return data; */
/* } */
