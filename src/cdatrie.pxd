# cython: profile=False
from libc cimport stdio

cdef extern from "../libdatrie/datrie/triedefs.h":
    ctypedef int AlphaChar # it should be utf32 letter
    ctypedef unsigned char TrieChar  # 1 byte
    ctypedef int TrieIndex
    ctypedef int TrieData  # int

cdef extern from "../libdatrie/datrie/alpha-map.h":

    struct AlphaMap:
        pass

    AlphaMap * alpha_map_new()
    void alpha_map_free (AlphaMap *alpha_map)
    AlphaMap * alpha_map_clone (AlphaMap *a_map)

    int alpha_map_add_range (AlphaMap *alpha_map, AlphaChar begin, AlphaChar end)
    int alpha_char_strlen (AlphaChar *str)

cdef extern from "../libdatrie/datrie/alpha-map-private.h":
    TrieChar alpha_map_char_to_trie (AlphaMap *alpha_map, AlphaChar ac)

    AlphaChar alpha_map_trie_to_char (AlphaMap *alpha_map, TrieChar tc)

    TrieChar * alpha_map_char_to_trie_str (AlphaMap  *alpha_map, AlphaChar *str)

    AlphaChar * alpha_map_trie_to_char_str (AlphaMap  *alpha_map, TrieChar  *str)


cdef extern from "../libdatrie/datrie/darray.h":
    # Double-array trie structure

    struct DArray:
        pass

    ctypedef bint (*DAEnumFunc) (TrieChar *key, TrieIndex sep_node, void *user_data)

    TrieIndex da_get_root (DArray *d)

    TrieIndex da_get_base (DArray *d, TrieIndex s)

    TrieIndex da_get_check (DArray *d, TrieIndex s)

    bint da_enumerate (DArray *d, DAEnumFunc enum_func, void *user_data)

    bint da_enumerate_recursive (DArray *d, TrieIndex state, DAEnumFunc enum_func, void *user_data)

cdef extern from "../libdatrie/datrie/tail.h":
    struct Tail:
        pass

    TrieData tail_get_data (Tail *t, TrieIndex index)
    TrieChar * tail_get_suffix(Tail *t, TrieIndex index)



cdef extern from "../libdatrie/datrie/trie.h":

    ctypedef struct Trie:
        pass
#        AlphaMap   *alpha_map
#        DArray     *da
#        Tail       *tail
#        bint        is_dirty

    ctypedef struct TrieState:
        pass
#        Trie *trie         # the corresponding trie
#        TrieIndex index  # index in double-array/tail structures
#        short suffix_idx   # suffix character offset, if in suffix
#        short is_suffix    # whether it is currently in suffix part

    ctypedef int TrieData

    int TRIE_CHAR_TERM
    int TRIE_DATA_ERROR

    ctypedef bint (*TrieEnumFunc) (AlphaChar *key, TrieData key_data, void *user_data)


    # ========== GENERAL FUNCTIONS ==========

    Trie * trie_new (AlphaMap *alpha_map)

    Trie * trie_new_from_file (char *path)

    Trie * trie_fread (stdio.FILE *file)

    void trie_free (Trie *trie)

    int trie_save (Trie *trie, char *path)

    int trie_fwrite (Trie *trie, stdio.FILE *file)

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

    bint trie_state_is_terminal(TrieState * s)

    bint trie_state_is_single (TrieState *s)

    bint trie_state_is_leaf(TrieState* s)

    TrieData trie_state_get_data (TrieState *s)

    bint trie_da_enum_func (TrieChar *key, TrieIndex sep_node, void *user_data)


cdef struct _TrieEnumData:
    Trie *trie
    TrieEnumFunc enum_func
    void *user_data

cdef struct _Trie:
    AlphaMap   *alpha_map
    DArray     *da
    Tail       *tail
    bint       is_dirty

cdef struct _TrieState:
    _Trie       *trie         # the corresponding trie
    TrieIndex   index  # index in double-array/tail structures
    short       suffix_idx   # suffix character offset, if in suffix
    short       is_suffix    # whether it is currently in suffix part

