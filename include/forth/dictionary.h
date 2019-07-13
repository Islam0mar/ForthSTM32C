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

#include "global.h"

typedef struct {
  char *name;  // maximum word length
  ForthObject object;
} ElementType;

typedef ElementType DictionaryEntry;

typedef struct dictionary_node {
  DictionaryNode next;
  DictionaryEntry entry;
} DictionaryNode;

typedef struct {
  DictionaryNode *head;
  DictionaryNode *tail;
} Dictionary;

Dictionary *GetDictPtr();
DictionaryNode *MakeDictionaryNode(DictionaryEntry item);
bool AddToTail(DictionaryEntry item, Dictionary *pd);
DictionaryNode *FindDictionaryItem(Dictionary *pd, char *name);
bool DeleteDictionaryItem(Dictionary *pd, char *name);
bool DictionaryEmpty(Dictionary *pd);
void CreateDictionary(Dictionary *pd);
int DictionarySize(Dictionary *pd);
void ClearDictionary(Dictionary *pd);
bool AddToDictionary(char *name, ForthObject obj, Dictionary *pd);
#define FORTH_DICT_ADD(name, obj) AddToDictionary(name, obj, GetDictPtr())

#endif /* DICTIONARY_H */
