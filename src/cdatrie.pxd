# cython: profile=False

cdef extern from "../libdatrie/datrie/triedefs.h":
    ctypedef int AlphaChar # it should be utf32 letter
    ctypedef int TrieChar  # 1 byte
    ctypedef int TrieIndex
    ctypedef int TrieData  # int

cdef extern from "../libdatrie/datrie/alpha-map.h":

    ctypedef struct AlphaMap:
        pass

    AlphaMap * alpha_map_new()
    void alpha_map_free (AlphaMap *alpha_map)
    AlphaMap * alpha_map_clone (AlphaMap *a_map)

    int alpha_map_add_range (AlphaMap *alpha_map, AlphaChar begin, AlphaChar end)
    int alpha_char_strlen (AlphaChar *str)


cdef extern from "../libdatrie/datrie/trie.h":
    ctypedef struct Trie:
        pass
    ctypedef struct TrieState:
        pass

    ctypedef int TrieData

    # Trie enumeration function
    #
    # @param key  : the key of the entry
    # @param data : the data of the entry
    # @param user_data : the user-supplied data on enumerate call
    #
    # @return TRUE to continue enumeration, FALSE to stop
    ctypedef bint (*TrieEnumFunc) (AlphaChar *key, TrieData key_data, void *user_data)


    # ========== GENERAL FUNCTIONS ==========

    Trie * trie_new (AlphaMap *alpha_map)

    Trie * trie_new_from_file (char *path)

    Trie * trie_fread (void *file) # FILE?

    void trie_free (Trie *trie)

    int trie_save (Trie *trie, char *path)

    int trie_fwrite (Trie *trie, void *file) # FILE?

    bint trie_is_dirty (Trie *trie)


    # =========== GENERAL QUERY OPERATIONS =========

    bint trie_retrieve (Trie *trie, AlphaChar *key, TrieData *o_data)

    bint trie_store (Trie *trie, AlphaChar *key, TrieData data)

    bint trie_store_if_absent (Trie *trie, AlphaChar *key, TrieData data)

    bint trie_delete (Trie *trie, AlphaChar *key)

    bint trie_enumerate (Trie *trie, TrieEnumFunc enum_func, void *user_data)

    # ======== STEPWISE QUERY OPERATIONS ========

    TrieState * trie_root (Trie *trie)


    # ========= TRIE STATE ===============

    TrieState * trie_state_clone (TrieState *s)

    void trie_state_copy (TrieState *dst, TrieState *src)

    void trie_state_free (TrieState *s)

    void trie_state_rewind (TrieState *s)

    bint trie_state_walk (TrieState *s, AlphaChar c)

    bint trie_state_is_walkable (TrieState *s, AlphaChar c)

    int TRIE_CHAR_TERM

    bint trie_state_is_terminal(TrieState * s)

    bint trie_state_is_single (TrieState *s)

    bint trie_state_is_leaf(TrieState* s)

    TrieData trie_state_get_data (TrieState *s)
