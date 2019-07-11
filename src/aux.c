/**
 *   \file aux.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#include <ctype.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "forth/aux.h"

ForthObject StrToForthObj(const char* s) {
  static char* end;
  static void* r;
  static uint8_t i;
  static ForthType t;
  static float f;
  static double d;
  static long double ld;
  static long long ll;
  t = kNull;
  for (; s[i] != '\0'; i++) {
  }
  if (i > 2) {
    if (toupper(s[i - 2]) == 'S' && s[i - 1] == '0') {
      t = kSingleFloat;
    } else if (toupper(s[i - 2]) == 'D' && s[i - 1] == '0') {
      t = kDoubleFloat;
    } else if (toupper(s[i - 2]) == 'L' && s[i - 1] == '0') {
      t = kLongFloat;
    }
  }
  switch (t) {
    case kSingleFloat: {
      f = strtof(s, &end);
      r = &f;
      break;
    }
    case kDoubleFloat: {
      d = strtod(s, &end);
      r = &d;
      break;
    }
    case kLongDoubleFloat: {
      ld = strtold(s, &end);
      r = &ld;
      break;
    }

    default:
      ll = strtoll(s, &end, 0);
      r = &ll;
      if (FORTH_IS_FIXNUM_VAL(ll)) {
        t = kFixNum;
      } else if (FORTH_IS_BIGNUM_VAL(ll)) {
        t = kBigNum;
      }
      break;
  }
  if (errno == ERANGE) {
    errno = 0;
    char err[PAD_SIZE + 17] = "RANGE ERROR, <";
    strcat(err, pad);
    strcat(err, ">.");
    ForthError(err);
  } else if (end != NULL) {  // not integer

    char err[PAD_SIZE + 20] = "NOT RECOGNIZED, <";
    strcat(err, pad);
    strcat(err, ">.");
    ForthError(err);
  }
  return ForthCreateObject((ForthData)r, t);
}
