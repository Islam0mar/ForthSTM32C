/**
 *   \file stack.c
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */

// #include <conio.h>
#include <stdio.h>
#include <stdlib.h>

#include "forth/stack.h"

void Push(StackEntry, Stack *);
void Pop(StackEntry *, Stack *);
/* StackEmpty: returns non-zero if the stack is empty
   Pre: The stack exists and it has been initialized.
   Post: Return non-zero if the stack is empty; zero, otherwise.
*/
static inline bool StackEmpty(Stack *ps) {
  return ps->top <= 0;
  // other possible code is:
  // return (ps->top == 0)
}
/* StackFull: returns non-zero if the stack is full.
   Pre: The stack exists and it has been initialized.
   Post: Return non-zero if the stack is full; return zero, otherwise.
 */
static inline bool StackFull(Stack *ps) {
  return ps->top >= MAXSTACK;
  // other possible code is:
  // return ps->top==MAXSTACK;
}
void CreateStack(Stack *);
void StackTop(StackEntry *, Stack *);
int StackSize(Stack *);
void ClearStack(Stack *);
void TraverseStack(Stack *, void (*)(StackEntry));

static Stack stack;
#define STACK_PTR (&stack)
StackEntry tos = 0;

void PopPSP(StackEntry *item_ptr) {
  if (!StackEmpty(STACK_PTR)) {
    Pop(item_ptr, STACK_PTR);
  } else {
    ForthError("STACK UNDERFLOW", "POP");
  }
}

void PushPSP(StackEntry item) {
  if (!StackFull(STACK_PTR)) {
    Push(item, STACK_PTR);
  } else {
    ForthError("STACK OVERFLOW", "PUSH");
  }
}

/*********************************************************************************/
/****************************** Array-based
 * implementation************************/
/*********************************************************************************/

/* Push : push an item onto the stack
   Pre: The stack exists and it is not full.
   Post: The argument item has been stored at the top of the stack. */
void Push(StackEntry item, Stack *ps) { ps->entry[ps->top++] = item; }

/* Pop: pop an item from the stack.
   Pre: The stack exists and it is not empty.
   Post: The item at the top of the stack has been removed and returned
         in *item  */
void Pop(StackEntry *item, Stack *ps) { *item = ps->entry[--ps->top]; }

/* CreateStack: initialize the stack to be empty.
   Pre: None.
   Post: The stack has been initialized to be empty.
*/
void CreateStack(Stack *ps) { ps->top = 0; }

/*
Pre:   The stack has been created and is not empty.
Post: The variable x is a copy of the top entry; the stack remains
      unchanged.
*/
void StackTop(StackEntry *item, Stack *ps) { /* void StackTop */
  *item = ps->entry[ps->top - 1]; /* ps->top references one beyond last entry*/
} /* void StackTop */

/*
Pre:  The stack has been created.
Post: The function returns the number of entries in stack.
*/
int StackSize(Stack *ps) { return ps->top; }

/*
Pre:  The stack has been created.
Post: Stack becoems empty
*/
void ClearStack(Stack *ps) { ps->top = 0; }

/*
Pre:   The stack has been created.
Post:  Visit Each element in the stack from the top to the bottom.
*/
void TraverseStack(Stack *ps, void (*pvisit)(StackEntry)) {
  for (int i = ps->top; i > 0; i--) (*pvisit)(ps->entry[i - 1]);
} /* void TraverseStack */
