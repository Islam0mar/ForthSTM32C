/**
 *   \file object.c
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#include "forth/object.h"
#include "forth/parse.h"

static inline void *ForthAlloc(ForthIndex s) {
  static void *temp;
  temp = malloc(s);
  if (temp == NULL) {
    ForthError("ALLOCATION FAILED!", "ForthAlloc");
  }
  return temp;
}

static inline void *ForthRealloc(ForthData d, ForthIndex s) {
  d = realloc(d, s);
  if (d == NULL) {
    ForthError("ALLOCATION FAILED!", "ForthRealloc");
  }
}

ForthData ForthCreateData(ForthType t) {
  static ForthData data = NULL;
  switch (FORTH_TYPE_MASK(t)) {
    case kCons: {
      data = ForthAlloc(sizeof(ForthCons));
      break;
    }
    case kFixNum: {
      data = -1;
      break;
    }
    case kBigNum: {
      data = ForthAlloc(sizeof(ForthBigNum));
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
    case kPointer: {
      data = NULL;
      break;
    }
    default:
      ForthError("UNKNOWN TYPE", "ForthCreateData");
      break;
  }
  return data;
}

ForthObject ForthCreateEmptyObject(ForthType t) {
  static ForthObject obj;
  obj.type = t;
  obj.data = ForthCreateData(t);
  return obj;
}

ForthObject ForthCreateCons(ForthObject a, ForthObject b) {
  ForthObject obj = ForthCreateEmptyObject(kCons);
  FORTH_CONS_CAR(x.data) = a;
  FORTH_CONS_CDR(x.data) = b;
  return obj;
}

ForthObject ForthCreateNull() {
  ForthObject obj = ForthCreateEmptyObject(kPointer);
  return obj;
}

ForthObject ForthCreateFixNum(ForthFixNum x) {
  ForthObject obj = ForthCreateEmptyObject(kFixNum);
  obj.data = x;
  return obj;
}

ForthObject ForthCreateBigNum(ForthBigNum x) {
  ForthObject obj = ForthCreateEmptyObject(kBigNum);
  *obj.data = x;
  return obj;
}

ForthObject ForthCreateSingleFloat(float x) {
  ForthObject obj = ForthCreateEmptyObject(kSingleFloat);
  *obj.data = x;
  return obj;
}

ForthObject ForthCreateDoubleFloat(double x) {
  ForthObject obj = ForthCreateEmptyObject(kDoubleFloat);
  *obj.data = x;
  return obj;
}

ForthObject ForthCreateLongDoubleFloat(long double x) {
  ForthObject obj = ForthCreateEmptyObject(kLongDoubleFloat);
  *obj.data = x;
  return obj;
}

ForthObject ForthCreateEmptyVector() {
  ForthObject obj = ForthCreateEmptyObject(kVector);
  ((ForthVector *)obj.data)->size = 0;
  ((ForthVector *)obj.data)->word = NULL;
  return obj;
}

ForthObject ForthCreateVector(ForthObject x) {
  ForthObject obj;
  obj = ForthCreateEmptyVector();
  ForthAddToVector(x, obj.data);
  return obj;
}

void ForthAddToVector(ForthObject x, ForthVector *v) {
  v->size++;
  v->word = ForthRealloc(v->word, v->size * sizeof(x));
  v->word[v->size - 1] = x;
}

ForthObject ForthCreateObject(ForthData x, ForthType t) {
  static ForthObject obj = NULL;
  switch (FORTH_TYPE_MASK(t)) {
    case kCons: {
      /* TODO: Unused!! */
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
    case kPointer: {
      obj.t = t;
      obj.data = x;
      break;
    }
    default:
      ForthError("UNKNOWN TYPE", "ForthCreateObject");
      break;
  }
  return obj;
}
void ForthRemoveObject(ForthObject obj) {
  switch (FORTH_TYPE_MASK(obj.type)) {
    case kCons: {
      ForthData d = obj.data;
      ForthRemoveObject(FORTH_CONS_CAR(d));
      ForthRemoveObject(FORTH_CONS_CDR(d));
      free(d);
      break;
    }
    case kFixNum: {
      break;
    }
    case kBigNum: {
      free(obj.data);
      break;
    }
    case kSingleFloat: {
      free(obj.data);
      break;
    }
    case kDoubleFloat: {
      free(obj.data);
      break;
    }
    case kLongDoubleFloat: {
      free(obj.data);
      break;
    }
    case kVector: {
      free(obj.data);
      break;
    }
    case kPointer: {
      free(obj.data);
      break;
    }
    default:
      ForthError("UNKNOWN TYPE", "ForthRemoveObject");
      break;
  }
}

void ForthRemoveFreeObject(ForthObject obj) {
  if (FORTH_FLAG_MASK(obj.type) == kFree) {
    ForthRemoveObject(obj);
  }
}



