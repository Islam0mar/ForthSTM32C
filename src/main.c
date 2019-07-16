/**
 *   \file main.c
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */


#include "hal/bsp.h"
#include "forth/dictionary.h"
#include "forth/words.h"

jmp_buf env;
uint8_t state;
int main(void) {
  Init();
  state = 0;
  setjmp(env);
  for (;;) {
    interpret();
  }
}

  
