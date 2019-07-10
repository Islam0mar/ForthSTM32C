/**
 *   \file aux.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

uint32_t StrToInt(const char* s) {
  char *end = NULL;
  long l = strtol(s, &end, 0);
  if (errno == ERANGE || l >= UINT32_MAX) {
    errno = 0;
    char err[PAD_SIZE + 17] = "RANGE ERROR, <";
    strcat(err, pad);
    strcat(err, ">.");
    ForthError(err);
  } else if(end != NULL){
    char err[PAD_SIZE + 20] = "NOT RECOGNIZED, <";
    strcat(err, pad);
    strcat(err, ">.");
    ForthError(err);
  }
  return l;
}
