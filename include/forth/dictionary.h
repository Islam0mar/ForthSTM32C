/**
 *   \file dictionary.h
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#ifndef DICTIONARY_H
#define DICTIONARY_H

#include "global.h"

typedef struct {
  char *name;  // maximum word length
  ForthObject object;
} ElementType;

typedef ElementType DictionaryEntry;

/* FIXME: change name dictionarynode!! */
typedef struct dictionarynode {
  struct dictionarynode *next;
  DictionaryEntry entry;
} DictionaryNode;

typedef struct {
  DictionaryNode *head;
  DictionaryNode *tail;
} Dictionary;

Dictionary *GetDictionaryPointer();
DictionaryNode *MakeDictionaryNode(DictionaryEntry item);
bool AddToTail(DictionaryEntry item, Dictionary *pd);
bool AddToHead(DictionaryEntry item, Dictionary *pd);
DictionaryNode *FindDictionaryItem(char *name, Dictionary *pd);
bool DeleteDictionaryItem(char *name, Dictionary *pd);
bool DictionaryEmpty(Dictionary *pd);
void CreateDictionary(Dictionary *pd);
int DictionarySize(Dictionary *pd);
void ClearDictionary(Dictionary *pd);
bool AddToDictionary(char *name, ForthObject obj, Dictionary *pd);
ForthObject GetDictionaryEntryObject(DictionaryNode *p);
char *GetDictionaryEntryName(DictionaryNode *p);
static inline void AddDictionaryObject(char *name, ForthObject obj) {
  AddToDictionary(name, obj, GetDictionaryPointer());
}

#endif /* DICTIONARY_H */
