/**
 *   \file dictionary.c
 *   \brief A Documented file.
 *
 *  Copyright (c) 2019 Islam Omar (io1131@fayoum.edu.eg)
 *
 */

#include "forth/dictionary.h"
#include "forth/global.h"
#include "forth/object.h"
#include "forth/parse.h"

DictionaryNode *MakeDictionaryNode(DictionaryEntry item) {
  DictionaryNode *p = malloc(sizeof(DictionaryNode));
  if (p != NULL) {
    p->entry = item;
    p->next = NULL;
  }
  return p;
}

bool AddToTail(DictionaryEntry item, Dictionary *pd) {
  DictionaryNode *p = MakeDictionaryNode(item);
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
  DictionaryNode *p = MakeDictionaryNode(item);
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

Dictionary *GetDictionaryPointer() {
  static Dictionary dict = {.head = NULL, .tail = NULL};
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

DictionaryNode *FindDictionaryItem(char *name, Dictionary *pd) {
  DictionaryNode *p = pd->head;
  for (; p; p = p->next) {
    if (strcmp(name, p->entry.name) == 0) {
      return p;
    }
  }
  return NULL;
}
ForthObject GetDictionaryEntryObject(DictionaryNode *p) {
  return p->entry.object;
}
char *GetDictionaryEntryName(DictionaryNode *p) { return p->entry.name; }

bool DeleteDictionaryItem(char *name, Dictionary *pd) {
  DictionaryNode *p = pd->head;
  DictionaryNode *prev_p = NULL;
  for (; p; p = p->next) {
    if (strcmp(name, p->entry.name) == 0) {
      if (FORTH_IS_FLASH(p->entry.object)) {
        /* TODO: remove flash */
        return false;
      } else {
        prev_p->next = p->next;
        free(p->entry.name);
        ForthRemoveObject(p->entry.object);
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
    node->entry.object = obj;
  } else {
    DictionaryEntry entry = {.object = obj};
    const size_t str_len = strlen(name) + 1;
    entry.name = malloc(sizeof(char) * str_len);
    if (entry.name == NULL) {
      return false;
    }
    strncpy(entry.name, name, str_len);
    /* FIXME: memleak */
    return AddToHead(entry, pd);
  }
  return true;
}
