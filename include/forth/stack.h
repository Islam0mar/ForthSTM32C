/**
 *   \file stack.h
 *   \brief A Documented file.
 *
 *  Detailed description
 *
 */
#ifndef STACK_H
#define STACK_H

#include "global.h"

typedef StackEntry uint32_t;

#define MAXSTACK 512U

extern StackEntry tos;

typedef struct stack{
	uint32_t top;
	StackEntry entry[MAXSTACK];
} Stack;

void PopPSP(StackEntry*);
void PushPSP(StackEntry);

#define PopTOS() PopPSP(&tos)
#define PushTOS() PushPSP(tos)


// void	Push			(StackEntry, Stack *);
// void	Pop				(StackEntry *, Stack *);
// int		StackEmpty		(Stack *);
// int		StackFull		(Stack *);
// void	CreateStack		(Stack *);
// void	StackTop		(StackEntry *, Stack *);
// int		StackSize		(Stack *);
// void	ClearStack		(Stack *);
// void	TraverseStack	(Stack *, void (*)(StackEntry));

#endif /* STACK_H */
