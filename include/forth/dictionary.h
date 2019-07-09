/*
 * @CreateTime: Jul 20, 2017 4:21 PM
 * @Author: Islam Omar
 * @Contact: io1131@fayoum.edu.eg
 * @Last Modified By: Islam Omar
 * @Last Modified Time: Jul 20, 2017 4:21 PM
 * @Description: Modify Here, Please
 */


#ifndef DICTIONARY_H
#define DICTIONARY_H

#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include "global.h"

// typedef enum { f_immediate, t_compile_only, t_hidden, t_idle } ForthTypes;
#define F_IMMED   0x80U   // immediate
#define F_COMPO   0x40U   // compile only
#define F_HIDDEN  0x20U  // hidden
#define F_FLASH   0x10U   // flash

typedef struct elementtype {
  char *name;  // maximum word length
  uint8_t flags;
  uint8_t length;  // function ptrs length
  void *ptr;
} ElementType;

typedef ElementType DictionaryEntry;

typedef struct dictionarynode {
  struct dictionarynode *next;
  DictionaryEntry entry;
} DictionaryNode;

typedef struct dictionary {
  DictionaryNode *head;
  DictionaryNode *tail;
  uint32_t size;
} Dictionary;

DictionaryNode *makeDictionaryNode(DictionaryEntry item);
bool addToTail(DictionaryEntry item, Dictionary *pd);
bool dictionaryEmpty(Dictionary *pd);
void createDictionary(Dictionary *pd);
int dictionarySize(Dictionary *pd);
void clearDictionary(Dictionary *pd);
bool addDictionaryEntry(char *name, uint8_t flags, uint8_t length,
                        FuncPtr ptr[], Dictionary *pd);

#endif
