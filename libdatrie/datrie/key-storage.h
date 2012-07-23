/*
 * key-storage.h - dynamic storage for keys
 */

#ifndef __STR_BUFFER_H
#define __STR_BUFFER_H

#include "triedefs.h"
#include "alpha-map.h"

typedef struct {
    TrieChar * trie_key;    /* < key in TrieChar* format */
    AlphaChar* alpha_key;   /* < key in AlphaChar* format */
    int length;             /* < current string length */
    int allocated;          /* < allocated length */

    AlphaMap * alpha_map;   /* < AlphaMap used for conversion */
} KeyStorage;


Bool ks_init (KeyStorage *ks, int initial_size, const AlphaMap* alpha_map);

Bool ks_ensure_size (KeyStorage* ks, int size);

void ks_free (KeyStorage* ks);

void ks_push (KeyStorage* ks, TrieChar tc, AlphaChar ac);

void ks_push_tc (KeyStorage* ks, TrieChar tc);

void ks_push_ac (KeyStorage* ks, AlphaChar ac);

void ks_terminate (KeyStorage* ks);

void ks_reverse (KeyStorage* ks);

void ks_clear (KeyStorage* ks);

void ks_pop (KeyStorage* ks, int count);

#endif