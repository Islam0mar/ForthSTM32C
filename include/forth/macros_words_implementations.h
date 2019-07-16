/**
 *   \file _words_implementations.h
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

/*
        QUIT AND INTERPRET
   ----------------------------------------------------------------------

        QUIT is the first FORTH function called, almost immediately after the
   FORTH system "boots". As explained before, QUIT doesn't "quit" anything.  It
   does some initialisation (in particular it clears the return stack) and it
   calls INTERPRET in a loop to interpret commands.  The reason it is called
   QUIT is because you can call it from your own FORTH words in order to "quit"
   your program and start again at the user prompt.

        INTERPRET is the FORTH interpreter ("toploop", "toplevel" or "REPL"
   might be a more accurate description -- see:
   http://en.wikipedia.org/wiki/REPL).
*/
FIRSTDEFCODE("QUIT", 0, quit,
             "Quit your program and start again at the user prompt",
             { longjmp(env, 0); });

DEFCODE(quit, "KEY", 0, key, "( -- c ) Receive one character", {
  PushTOS();
  UpdateTOSWithValueType(TIBReadChar(), kFixNum);
});

DEFCODE(key, "KEY?", 0, is_key, "( -- 0|1 ) Receive one character", {
  PushTOS();
  UpdateTOSWithValueType((TIBEmpty()) ? 0 : 1, kFixNum);
});

DEFCODE(is_key, "WORD", 0, word,
        "( -- addr length ) reads next word from buffer", {
          static uint8_t i;
          for (i = 0;;) {
            pad[i] = TIBReadChar();
            switch (pad[i]) {
              case ' ': {
                break;
              }
              case '\\': {
                do {
                  pad[i] = TIBReadChar();
                } while (pad[i] != '\n');
                break;
              }
              case '(': {
                do {
                  pad[i] = TIBReadChar();
                } while (pad[i] != ')');
                break;
              }
              default: {
                do {
                  ++i;
                  if (i >= PAD_SIZE) {
                    ForthError("PAD size over flow", "");
                  }
                  pad[i] = TIBReadChar();
                } while (pad[i] != ' ');
                pad[i] = '\0';
                break;
              }
            }
          }
          PushTOS();
          UpdateTOSWithValueType(pad, kPointer);
          PushTOS();
          UpdateTOSWithValueType(i, kFixNum);
        });

DEFCODE(word, "(FIND)", 0, paren_find, "( addr length -- dictionary_address )",
        {
          PopTOS();
          UpdateTOSWithValueType(
              FindDictionaryItem(GetTOSPtr()->data, GetDictionaryPointer()),
              kPointer);
        });

DEFCODE(paren_find, ">CFA", 0, tcfa,
        "( dictionary_address -- executable_address )",
        { UpdateTOSWithObject(GetDictionaryEntryObject(GetTOSPtr()->data)); });

DEFCODE(tcfa, ">DFA", 0, tdfa, "( dictionary_address -- data_field_address )",
        { tcfa(); });

DEFCODE(tdfa, ",", 0, comma,
        "( n -- ) writes the top element from the stack at DP", {
          if (FORTH_IS_CMP_TO_FLASH) {
          } else {
            ForthAddToVector(*GetTOSPtr(),
                             GetDictionaryPointer()->head->entry.object.data);
            PopTOS();
          }
          /* here */
        });

/*       This interpreter is pretty simple, but remember that in FORTH you can
always override it later with a more powerful one!
*/
DEFCODE(comma, "INTERPRET", 0, interpret, "Interpret inputs", {
  word();
  ForthObject parsed_number = *GetTOSPtr();
  paren_find();
  /* word not found in dict */
  if (GetTOSPtr()->data == NULL) {
    parsed_number = StrToForthObj(parsed_number.data);
    if (FORTH_IS_EXE_STATE) { /* exec */
      /* PushTOS(); */
      *GetTOSPtr() = parsed_number;
    } else { /* compile mode */
      *GetTOSPtr() = parsed_number;
      comma();
    }
  } else { /* word found in dict */
    char *word_name = GetDictionaryEntryName(GetTOSPtr()->data);
    tcfa(); /* >CFA */
    ForthType t = GetTOSPtr()->type;
    /* immediate word */
    if (BITMASK_CHECK_SET(t, kImmediate) || FORTH_IS_EXE_STATE) {
      if (FORTH_IS_EXE_STATE && BITMASK_CHECK_SET(t, kCompileOnly)) {
        ForthError("COMPILATION ONLY WORD", word_name);
      }
      exe_word();
    } else { /* compile state */
      comma();
    }
  }
});

DEFCODE(interpret, "EXECUTE-WORD", 0, exe_word, "execute word", {
  if (FORTH_FLAG_MASK(GetTOSPtr()->type) == kExecutable) {
    if (FORTH_TYPE_MASK(GetTOSPtr()->type) == kPointer) {
      (*(ForthFuncPtr)GetTOSPtr()->data)();
    } else { /* vector of words */
      static ForthVector *v;
      static uint8_t i;
      v = (ForthVector *)(GetTOSPtr()->data);
      PopTOS();
      for (i = 0; i < v->size; i++) {
        UpdateTOSWithObject(v->word[i]);
        exe_word();
      }
    }
    PopTOS();
  }
});
DEFCODE(exe_word, "CHAR", 0, _char,
        " ( -- c ) put the ASCII code of the first character of the next word",
        {
          word();
          PopTOS();
          UpdateTOSWithValueType(((char *)GetTOSPtr()->data)[0], kFixNum);
        });

DEFCODE(_char, ".S", 0, print_stack,
        " ( -- c ) put the ASCII code of the first character of the next word",
        { PrintStack(); });
DEFCODE(print_stack, "PAUSE", 0, pause,
        " multi-tasking",
        /* TODO: multi-tasking */
        { ; });

/* @ EXECUTE ( xt -- ) jump to the address on the stack */
/* 	defcode "EXECUTE",7,,EXECUTE */
/*     ldr r1, [tos] */
/* 	popTOS */
/* bx r1 */

/*         }); */

// //   ?RX		( -- c T | F )
// //		Return input character and true, or a false if no input.

// void QRX(void) {}

// //   TX!		( c -- )
// //		Send character c to the output device.
// void TXSTO(void) {}

// //   !IO		( -- )
// //		Initialize the serial I/O devices.
// void STOIO(void) {}

// //// The kernel

// //   doLIT	( -- w )
// //		Push an inline literal.
// void DOLIT(void) {}

// //   doLIST	( a -- )
// //		Process colon list.
// void DOLST(void)

//     //   EXIT	( -- )
//     //		Terminate a colon definition.

//     void EXIT

//     //   EXECUTE	( ca -- )
//     //		Execute the word at ca.

//     // void EXECU

//     //   next	( -- )
//     //		Run time code for the single index loop.
//     //		: next ( -- ) \ hilevel model
//     //		  r> r> dup if 1 - >r @ >r exit then drop cell+ >r //

//     void DONXT

//     //   ?branch	( f -- )
//     //		Branch if flag is zero.

//     void QBRAN

//     //   branch	( -- )
//     //		Branch to an inline address.

//     void BRAN

//     //   !		( w a -- )
//     //		Pop the data stack to memory.

//     void STORE

//     //   @		( a -- w )
//     //		Push memory location to the data stack.

//     void AT

//     //   C!		( c b -- )
//     //		Pop the data stack to byte memory.

//     void CSTOR

//     //   C@		( b -- c )
//     //		Push byte memory location to the data stack.

//     void CAT

//     //   RP@		( -- a )
//     //		Push the current RP to the data stack.

//     void RPAT

//     //   RP!		( a -- )
//     //		Set the return stack pointer.

//     void RPSTO

//     //   R>		( -- w )
//     //		Pop the return stack to the data stack.

//     void RFROM

//     //   R@		( -- w )
//     //		Copy top of return stack to the data stack.

//     void RAT

//     //   >R		( w -- )
//     //		Push the data stack to the return stack.

//     void TOR

//     //   SP@		( -- a )
//     //		Push the current data stack pointer.

//     void SPAT

//     //   SP!		( a -- )
//     //		Set the data stack pointer.

//     void SPSTO

//     //   DROP	( w -- )
//     //		Discard top stack item.

//     void DROP

//     //   DUP		( w -- w w )
//     //		Duplicate the top stack item.

//     void DUPP

//     //   SWAP	( w1 w2 -- w2 w1 )
//     //		Exchange top two stack items.

//     void SWAP

//     //   OVER	( w1 w2 -- w1 w2 w1 )
//     //		Copy second stack item to top.

//     void OVER

//     //   0<		( n -- t )
//     //		Return true if n is negative.

//     void ZLESS

//     //   AND		( w w -- w )
//     //		Bitwise AND.

//     void ANDD

//     //   OR		( w w -- w )
//     //		Bitwise inclusive OR.

//     void ORR

//     //   XOR		( w w -- w )
//     //		Bitwise exclusive OR.

//     void XORR

//     //   UM+		( w w -- w cy )
//     //		Add two numbers, return the sum and carry flag.

//     void UPLUS
