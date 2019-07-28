/**
 *   \file parse.h
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#ifndef PARSE_H
#define PARSE_H

#include "global.h"

ForthObject StrToForthObj(char* s);
/* char* itoa(int val, int base); */
void ForthError(const char* err_message, const char* word);
void ForthWarning(const char* err_message, const char* word);
void ForthPrint(char* s);
#define FORTH_ASSERT(test_, msg_) ((test_) ? (void)0 : ForthError(msg_, ""))

#endif /* PARSE_H */
