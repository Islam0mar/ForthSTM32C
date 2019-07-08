/*

 * @CreateTime: Jul 20, 2017 4:21 PM
 * @Author: Islam Omar
 * @Contact: io1131@fayoum.edu.eg
 * @Last Modified By: Islam Omar
 * @Last Modified Time: Jul 20, 2017 4:21 PM
 * @Description: Modify Here, Please
 */

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "hal/bsp.h"
#include "forth/dictionary.h"
#include "forth/words.h"


int main(void) {
  init();
  /* DictionaryEntry code; */
  /* loadDictionaryEntry(code, "and", 3); */
  /* code.IP[0] = &xx; */
  /* (*code.IP[0])(); */
  /* NEXT(); */

  // enable fly chech mode instruction pointer

  return 0;
}

/*
int stackptr;
asm
{
    LDR r0, =stackptr  // put address of C variable stackptr in r0
    MOV r1, sp         // move value of sp to r1
    STR r1, [r0]       // put value of r1 in address contained in r0 (stackptr)
}*/
