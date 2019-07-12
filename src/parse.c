/**
 *   \file aux.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#include <ctype.h>
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "forth/parse.h"

char *itoa(int val, int base) {
  static char buf[32] = {0};

  int i = 30;

  for (; val && i; --i, val /= base) {
    buf[i] = "0123456789abcdef"[val % base];
  }

  return &buf[i + 1];
}

void ForthError(const char *err_message, const char *word) {
  SendErrorMsg("Error: ");
  const char *fmt = "%s, <%s>.\n";
  const int kSize = snprintf(NULL, 0, fmt, err_message, word);
  char buf[kSize + 1];  // note +1 for terminating null byte
  snprintf(buf, sizeof buf, fmt, err_message, word);
  SendErrorMsg(buf);
  SendErrorMsg("Excuting QUIT...");
  TIBFlush();
  quit();
}

ForthObject StrToForthObj(const char *s) {
  static char *end;
  static void *r;
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
      } else {
        errno = ERANGE;
      }
      break;
  }
  if (errno == ERANGE) {
    errno = 0;
    ForthError("RANGE ERROR", pad);
  } else if (end != NULL) {  // not integer
    ForthError("NOT RECOGNIZED", pad);
  }
  return ForthCreateObject((ForthData)r, t);
}
