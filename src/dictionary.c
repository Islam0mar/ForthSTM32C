/*
 * @CreateTime: Jul 20, 2017 4:21 PM
 * @Author: Islam Omar
 * @Contact: io1131@fayoum.edu.eg
 * @Last Modified By: Islam Omar
 * @Last Modified Time: Jul 20, 2017 4:21 PM
 * @Description: Modify Here, Please
 */

#include "forth/dictionary.h"
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

DictionaryNode *MakeDictionaryNode(DictionaryEntry item) {
  DictionaryNode *p;

  p = (DictionaryNode *)malloc(sizeof(DictionaryNode));
  if (p != NULL) {
    p->entry = item;
    p->next = NULL;
  }
  return p;
}

bool AddToTail(DictionaryEntry item, Dictionary *pd) {
  DictionaryNode *p = makeDictionaryNode(item);
  if (p == NULL) {
    return false;
  }
  if (pd->head == NULL && pd->tail == NULL) {
    pd->head = p;
    pd->tail = p;
    return true;
  }
  pd->tail->next = p;
  pd->tail = p;
  return true;
}

bool AddToHead(DictionaryEntry item, Dictionary *pd) {
  DictionaryNode *p = makeDictionaryNode(item);
  if (p == NULL) {
    return false;
  }
  if (pd->head == NULL && pd->tail == NULL) {
    pd->head = p;
    pd->tail = p;
    return true;
  }
  p->next = pd->head;
  pd->head = p;
  return true;
}

bool DictionaryEmpty(Dictionary *pd) { return pd->head == NULL; }

Dictionary *GetDictPtr() {
  static dict = {.head = NULL, .tail = NULL};
  return &dict;
}

void CreateDictionary(Dictionary *pd) { pd->head = pd->tail = NULL; }

int DictionarySize(Dictionary *pd) {
  int x;
  DictionaryNode *ptrs = pd->head;
  for (x = 0; ptrs; ptrs = ptrs->next) x++;
  return x;
}

void ClearDictionary(Dictionary *pd) {
  DictionaryNode *p = pd->head;
  while (p) {
    p = p->next;
    free(pd->head);
    pd->head = p;
  }
  pd->tail = pd->head;
}

DictionaryNode *FindDictionaryItem(Dictionary *pd, char *name) {
  DictionaryNode *p = pd->head;
  for (; p; p = p->next) {
    if (strcmp(name, p->entry.name) == 0) {
      return p;
    }
  }
  return NULL;
}

bool DeleteDictionaryItem(Dictionary *pd, char *name) {
  DictionaryNode *p = pd->head;
  DictionaryNode *prev_p = NULL;
  for (; p; p = p->next) {
    if (strcmp(name, p->entry.name) == 0) {
      if (FORTH_IS_FLASH(p->entry)) {
        // TODO: remove flash
        return false;
      } else {
        prev_p->next = p->next;
        free(p->entry.name);
        free(p->entry.ptr);
        free(p);
        return true;
      }
    }
    prev_p = p;
  }
  return false;
}

bool AddToDictionary(char *name, ForthObject obj, Dictionary *pd) {
  DictionaryNode *node = FindDictionaryItem(name, pd);
  if (node != NULL) {
    ForthWarning("Word overwritten", name);
    node->object = obj;
  } else {
    DictionaryEntry entry = {.object = obj};
    const size_t str_len = strlen(name) + 1;
    entry.name = malloc(sizeof(char) * str_len);
    if (entry.name == NULL) return false;
    strncpy(entry.name, name, str_len);
    return addToHead(entry, pd);
  }
}
