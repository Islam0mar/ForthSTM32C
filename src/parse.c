/**
 *   \file aux.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */

#include <stdio.h>

#include "forth/object.h"
#include "forth/parse.h"
#include "forth/stack.h"
#include "forth/tib.h"
#include "forth/words.h"
#include "hal/bsp.h"

char *itoa(int val, int base) {
  static char buf[32] = {0};
  int i = 31;

  do {
    buf[i] = "0123456789abcdef"[val % base];
    --i;
    val /= base;
  } while (val && i);

  return &buf[i + 1];
}

void ForthError(const char *err_message, const char *word) {
  SendMsg("Error: ");
  const char *fmt = "%s, <%s>.\n";
  const int kSize = snprintf(NULL, 0, fmt, err_message, word);
  char buf[kSize + 1];  // note +1 for terminating null byte
  snprintf(buf, sizeof buf, fmt, err_message, word);
  SendMsg(buf);
  SendMsg("Excuting QUIT...\n");
  TIBFlush();
  quit();
}

void ForthWarning(const char *err_message, const char *word) {
  SendMsg("Warning: ");
  const char *fmt = "%s, <%s>.\n";
  const int kSize = snprintf(NULL, 0, fmt, err_message, word);
  char buf[kSize + 1];  // note +1 for terminating null byte
  snprintf(buf, sizeof buf, fmt, err_message, word);
  SendMsg(buf);
  SendMsg("Execution continues...\n");
}

void ForthPrint(char *s) { SendMsg(s); }

ForthObject StrToForthObj(const char *s) {
  static char *end = NULL;
  static ForthData r;
  static uint8_t i;
  static ForthType t;
  static float f;
  static double d;
  static long double ld;
  static long long ll;
  t = kPointer;
  for (i = 0; s[i] != '\0'; i++) {
  }
  if (i > 2) {
    if (toupper(s[i - 2]) == 'S' && s[i - 1] == '0') {
      t = kSingleFloat;
    } else if (toupper(s[i - 2]) == 'D' && s[i - 1] == '0') {
      t = kDoubleFloat;
    } else if (toupper(s[i - 2]) == 'L' && s[i - 1] == '0') {
      t = kLongDoubleFloat;
    }
  }
  switch (t) {
    case kSingleFloat: {
      f = strtof(s, &end);
      r = (ForthData)&f;
      break;
    }
    case kDoubleFloat: {
      d = strtod(s, &end);
      r = (ForthData)&d;
      break;
    }
    case kLongDoubleFloat: {
      ld = strtold(s, &end);
      r = (ForthData)&ld;
      break;
    }

    default:
      ll = strtoll(s, &end, 0);
      if (FORTH_IS_FIXNUM_VAL(ll)) {
        t = kFixNum;
        r = ll;
      } else if (FORTH_IS_BIGNUM_VAL(ll)) {
        t = kBigNum;
        r = (ForthData)&ll;
      } else {
        errno = ERANGE;
      }
      break;
  }
  if (errno == ERANGE) {
    errno = 0;
    PopTOS();
    ForthError("RANGE ERROR", s);
  } else if (*end != '\0') {  // not integer
    PopTOS();
    ForthError("NOT RECOGNIZED", s);
  }
  return ForthCreateObject(r, t);
}
