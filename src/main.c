/**
 *   \file main.c
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#include "forth/forth.h"
#include "hal/bsp.h"

jmp_buf env;
uint8_t state = 0;
uint8_t base = 10;
int main(void) {
  BspInit();
  WordsInit();
  ForthPrint("CForth ");
  ForthPrint(FORTH_VERSION_STRING);
  ForthPrint("\n");
  setjmp(env);
  IrqOn();
  for (;;) {
    interpret();
  }
}
