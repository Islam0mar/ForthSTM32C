/**
 *   \file stack.h
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */
#ifndef STACK_H
#define STACK_H

#include "global.h"
#include "object.h"

#define MAXSTACK 512U

typedef ForthObject StackEntry;

typedef struct stack {
  uint16_t top;
  StackEntry entry[MAXSTACK];
} Stack;

void PopPSP(StackEntry *);
void PushPSP(StackEntry);

void PopTOS();
void PushTOS();
void UpdateTOSWithValueType(ForthData val, ForthType t);
void UpdateTOSWithNonFreeValueType(ForthData val, ForthType t);
void UpdateTOSWithObject(StackEntry);
StackEntry *GetTOSPtr();

void Push(StackEntry, Stack *);
void Pop(StackEntry *, Stack *);
/* int    StackEmpty    (Stack *); */
/* int    StackFull   (Stack *); */
void CreateStack(Stack *);
void StackTop(StackEntry *, Stack *);
int StackSize(Stack *);
void ClearStack(Stack *);
void TraverseStack(Stack *, void (*)(StackEntry));
void PrintStack();
#endif /* STACK_H */
