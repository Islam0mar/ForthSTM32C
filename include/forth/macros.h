/**
 *   \file macros.h
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#ifndef MACROS_H
#define MACROS_H

#include "dictionary.h"
/* gcc -E words.h -o o.c */

/* From */
/* https://www.embedded.com/design/programming-languages-and-tools/4443209/Template-meta-programming-in-C-vs-opaque-pointer
 */
/* MACRO_CAT expands extra argument and concatenate with the first */

#define MACRO_CAT(a, ...) a##__VA_ARGS__

/* FUNCTION creates the function name ‘f’ with suffix ‘n’ */

#define FUNCTION(f, n) MACRO_CAT(f, n)

// From
// https://stackoverflow.com/questions/5459868/concatenate-int-to-string-using-c-preprocessor
#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)
#define FORTH_VERSION_STRING \
  STR(VERSION_MAJOR) "." STR(VERSION_MINOR) "." STR(VERSION_PATCH)

/* From */
// https://codecraft.co/2014/11/25/variadic-macros-tricks/
#define _GET_NTH_ARG(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, _11, _12, _13, \
                     _14, _15, _16, _17, _18, _19, _20, _21, N, ...)         \
  N
#define COUNT_VARARGS(...)                                                     \
  _GET_NTH_ARG(__VA_ARGS__, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, \
               8, 7, 6, 5, 4, 3, 2, 1)

/* From */
/* https://stackoverflow.com/questions/44479282/preprocessor-concatenate-string-to-each-argument-in-va-args
 */
#define EVAL(...) __VA_ARGS__
#define VARCOUNT(...) EVAL(COUNT_VARARGS(...))
#define GLUE(X, Y) GLUE_I(X, Y)
#define GLUE_I(X, Y) X##Y
#define FIRST(...) EVAL(FIRST_I(__VA_ARGS__, ))
#define FIRST_I(X, ...) X
#define TUPLE_TAIL(...) EVAL(TUPLE_TAIL_I(__VA_ARGS__))
#define TUPLE_TAIL_I(X, ...) (__VA_ARGS__)

#define TRANSFORM(NAME_, ARGS_) (GLUE(TRANSFORM_, VARCOUNT ARGS_)(NAME_, ARGS_))
#define TRANSFORM_1(NAME_, ARGS_) NAME_ ARGS_
#define TRANSFORM_2(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_1(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_3(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_2(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_4(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_3(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_5(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_4(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_6(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_5(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_7(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_6(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_8(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_7(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_9(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_8(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_10(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_9(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_11(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_10(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_12(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_11(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_13(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_12(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_14(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_13(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_15(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_14(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_16(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_15(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_17(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_16(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_18(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_17(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_19(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_18(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_20(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_19(NAME_, TUPLE_TAIL ARGS_)
#define TRANSFORM_21(NAME_, ARGS_) \
  NAME_(FIRST ARGS_), TRANSFORM_20(NAME_, TUPLE_TAIL ARGS_)

#define APPEND_NODE_STR(X) GLUE(X, _node.entry)
#define MAKE_INITIALIZER(...) \
  { __VA_ARGS__ }
#define FUN_TO_FORTH_OBJECT(...) \
  EVAL(MAKE_INITIALIZER TRANSFORM(APPEND_NODE_STR, (__VA_ARGS__)))
#define ADDRS(x) &x

#endif /* MACROS_H */

// ================================================================== //
// FORTH_DEFINE_IMPLEMENTATIONS
// ================================================================== //
#ifdef FORTH_DEFINE_IMPLEMENTATIONS

/* implement the basic definition primitive */
#define FIRSTDEFCODE(name_str, flags, func, _comnt, BLOCK)                     \
  void func() BLOCK;                                                           \
  const DictionaryNode func##_node = {                                         \
      .next = NULL,                                                            \
      .entry = {.object = {.data = (ForthData)&func,                           \
                           .type = (flags | kPointer | kFlash | kExecutable)}, \
                .name = name_str}}

#define DEFCODE(previous_word, name_str, flags, func, _comnt, BLOCK)           \
  void func() BLOCK;                                                           \
  const DictionaryNode func##_node = {                                         \
      .next = ADDRS(previous_word##_node),                                     \
      .entry = {.object = {.data = (ForthData)&func,                           \
                           .type = (flags | kPointer | kFlash | kExecutable)}, \
                .name = name_str}}

#define DEFWORD(previous_word, name_str, flags, func, _comnt, words...)       \
  const ForthObject obj[COUNT_VARARGS(words)] = {FUN_TO_FORTH_OBJECT(words)}; \
  const ForthVector v = {.size = COUNT_VARARGS(words), .word = obj};          \
  const DictionaryNode func##_node = {                                        \
      .next = ADDRS(previous_word##_node),                                    \
      entry = {.object = {.data = (ForthData)&v,                              \
                          .type = (flags | kVector | kFlash | kExecutable)},  \
               .name = name_str}}

#endif /* FORTH_DEFINE_IMPLEMENTATIONS */

// ================================================================== //
// FORTH_DEFINE_HEADERS
// ================================================================== //
#ifdef FORTH_DEFINE_HEADERS

#define FIRSTDEFCODE(name_str, flags, func, _comnt, BLOCK) \
  void func();                                             \
  extern const DictionaryNode func##_node

#define DEFCODE(next, name_str, flags, func, _comnt, BLOCK) \
  void func();                                              \
  extern const DictionaryNode func##_node

#define DEFWORD(next, name_str, flags, func, _comnt, words...) \
  extern const DictionaryNode func##_node

#endif /* FORTH_DEFINE_HEADERS */
