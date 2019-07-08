#ifndef MACROS_H
#define MACROS_H

#include "dictionary.h"
// gcc -E words.h -o o.c  
#define VERSION_MAJOR 1
#define VERSION_MINOR 0
#define VERSION_PATCH 0

// From https://stackoverflow.com/questions/5459868/concatenate-int-to-string-using-c-preprocessor
#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)
#define FORTH_VERSION_STRING STR(VERSION_MAJOR) "." STR(VERSION_MINOR) "." STR(VERSION_PATCH)

// https://codecraft.co/2014/11/25/variadic-macros-tricks/
#define _GET_NTH_ARG(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, _14, _15, _16, _17, _18, _19, _20, _21, N, ...) N
#define COUNT_VARARGS(...) _GET_NTH_ARG(__VA_ARGS__, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1)


// ================================================================== //
// FORTH_DEFINE_PRIMITIVES
// ================================================================== //
#ifdef FORTH_DEFINE_PRIMITIVES

// implement the basic definition primitive
#define DEFCODE(NEXT, name_str, FLAGS, func, _comnt, BLOCK)  \
  void func() BLOCK \
  const DictionaryNode func ## _node = {.next = NEXT, .entry = {.flags = FLAGS, .length = 1, .ptr = (void*)&func}}

#define DEFWORD(NEXT, name_str, FLAGS, func,_comnt, words...) \
  FuncPtr functions[COUNT_VARARGS(words)] = {words}; \
  const DictionaryNode func ## _node = {.next = NEXT, .entry = {.flags = FLAGS, .length = COUNT_VARARGS(words), .ptr = (void*)functions}}

// #define defvar(next, name_str, flags, func,_comnt, words...) 
// //   FuncPtr functions[COUNT_VARARGS(words)] = {words}; 
// //   const DictionaryEntry func ## _entry = {.flags = flags, .length = COUNT_VARARGS(words), .ptr = (void*)functions}; 
// //   const DictionaryNode func ## _node = {.next = next, .entry = entry}



#endif // FORTH_DEFINE_PRIMITIVES


// ================================================================== //
// FORTH_DEFINE_HEADERS
// ================================================================== //
#ifdef FORTH_DEFINE_HEADERS

#define DEFCODE(next, name_str, flags, func, _comnt, BLOCK)  \
  void func();                \
  extern const DictionaryNode func ## _node

#define DEFWORD(next, name_str, flags, func, _comnt, words...) \
  extern const DictionaryNode func ## _node 


#endif // FORTH_DEFINE_HEADERS

#endif /* MACROS_H */



