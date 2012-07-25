#include <stdlib.h>
#include <string.h>
#include "key-storage.h"
#include "alpha-map-private.h"

Bool ks_init (KeyStorage *ks, int initial_size, const AlphaMap* alpha_map) {
    ks->trie_key = malloc(initial_size * sizeof(TrieChar));
    if (NULL == ks->trie_key)
        return FALSE;

//    ks->alpha_key = malloc(initial_size * sizeof (AlphaChar));
//    if (NULL == ks->alpha_key) {
////        free (ks->trie_key);
//        return FALSE;
//    }

    ks->allocated = initial_size;
    ks->alpha_map = alpha_map;
    ks_clear(ks);
    return TRUE;
}

Bool ks_ensure_size (KeyStorage* ks, int size) {
    if (ks->allocated > size)
        return TRUE;

    int next_size = ks->allocated + 20;
    while (next_size < size)
        next_size += 20;
        //next_size *= 2;

    ks->trie_key = realloc(ks->trie_key, next_size * sizeof(TrieChar));
    if (NULL == ks->trie_key)
        return FALSE;

//    ks->alpha_key = realloc(ks->alpha_key, next_size * sizeof(AlphaChar));
//    if (NULL == ks->alpha_key) {
//        // how to handle trie_key?
//        return FALSE;
//    }

    ks->allocated = next_size;
    return TRUE;
}

void ks_free (KeyStorage *ks) {
    free(ks->trie_key);
//    free(ks->alpha_key);
}

void ks_push (KeyStorage* ks, TrieChar tc, AlphaChar ac) {
    ks_ensure_size (ks, ks->length + 1);
    ks->trie_key[ks->length] = tc;
//    ks->alpha_key[ks->length] = ac;
    ++(ks->length);
}

void ks_push_tc (KeyStorage* ks, TrieChar tc) {
//    ks_ensure_size (ks, ks->length + 1);
//    ks->alpha_key[ks->length++] = ac;

//    AlphaChar ac = alpha_map_trie_to_char (ks->alpha_map, tc);
//    ks_push_ac (ks, ac);
    ks_ensure_size (ks, ks->length + 1);
    ks->trie_key[ks->length++] = tc;
//    ++(ks->length);
//    ks_push (ks, tc, ac);
}

void ks_push_ac (KeyStorage* ks, AlphaChar ac) {
//    ks_ensure_size (ks, ks->length + 1);
//    ks->alpha_key[ks->length++] = ac;
//    ++(ks->length);
    TrieChar tc = alpha_map_char_to_trie (ks->alpha_map, ac);
    ks_push_tc (ks, tc);
}

void ks_pop (KeyStorage* ks, int count) {
    if (ks->length >= count) {
        ks->length -= count;
    }
    else{
        ks->length = 0;
    }
}

void ks_terminate (KeyStorage* ks) {
    if (0 == ks->trie_key[ks->length] ) { // && 0 == ks->trie_key[ks->length]) {
        /* string is already terminated */
        return;
    }

    ks_push (ks, 0, 0);
    /* do not take trailing 0 in account */
    ks->length--;
}

void ks_reverse (KeyStorage* ks) {
    TrieChar* trie_key = ks->trie_key;
//    AlphaChar* alpha_key = ks->alpha_key;

    int key_length = ks->length;
    int i;

    for (i = 0; i < --key_length; i++) {
        TrieChar trie_temp;
//        AlphaChar alpha_temp;

        trie_temp = trie_key[i];
        trie_key[i] = trie_key[key_length];
        trie_key[key_length] = trie_temp;

//        alpha_temp = alpha_key[i];
//        alpha_key[i] = alpha_key[key_length];
//        alpha_key[key_length] = alpha_temp;
    }
}

void ks_clear (KeyStorage* ks) {
    ks->length = 0;
    ks_terminate (ks);
}
