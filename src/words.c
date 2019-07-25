/**
 *   \file words.c
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#include "forth/words.h"
#include "forth/global.h"
#include "forth/parse.h"
#include "forth/stack.h"
#include "forth/tib.h"

#define FORTH_DEFINE_IMPLEMENTATIONS
#include "forth/macros.h"
#include "forth/macros_words_implementations.h"
#undef FORTH_DEFINE_IMPLEMENTATIONS

void WordsInit() {
  GetDictionaryPointer()->head = &pause_node;
}
