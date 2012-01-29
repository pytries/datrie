/* -*- Mode: C; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- */
/*
 * libdatrie - Double-Array Trie Library
 * Copyright (C) 2006  Theppitak Karoonboonyanan <thep@linux.thai.net>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * trie.c - Trie data type and functions
 * Created: 2006-08-11
 * Author:  Theppitak Karoonboonyanan <thep@linux.thai.net>
 */

#include <stdlib.h>
#include <string.h>

#include "trie.h"
#include "fileutils.h"
#include "alpha-map.h"
#include "alpha-map-private.h"
#include "darray.h"
#include "tail.h"

/**
 * @brief Trie structure
 */
struct _Trie {
    AlphaMap   *alpha_map;
    DArray     *da;
    Tail       *tail;

    Bool        is_dirty;
};

/**
 * @brief TrieState structure
 */
struct _TrieState {
    const Trie *trie;       /**< the corresponding trie */
    TrieIndex   index;      /**< index in double-array/tail structures */
    short       suffix_idx; /**< suffix character offset, if in suffix */
    short       is_suffix;  /**< whether it is currently in suffix part */
};

/*------------------------*
 *   INTERNAL FUNCTIONS   *
 *------------------------*/

#define trie_da_is_separate(da,s)      (da_get_base ((da), (s)) < 0)
#define trie_da_get_tail_index(da,s)   (-da_get_base ((da), (s)))
#define trie_da_set_tail_index(da,s,v) (da_set_base ((da), (s), -(v)))

static TrieState * trie_state_new (const Trie *trie,
                                   TrieIndex   index,
                                   short       suffix_idx,
                                   short       is_suffix);

static Bool
trie_store_conditionally (Trie            *trie,
                          const AlphaChar *key,
                          TrieData         data,
                          Bool             is_overwrite);

static Bool        trie_branch_in_branch (Trie           *trie,
                                          TrieIndex       sep_node,
                                          const TrieChar *suffix,
                                          TrieData        data);

static Bool        trie_branch_in_tail   (Trie           *trie,
                                          TrieIndex       sep_node,
                                          const TrieChar *suffix,
                                          TrieData        data);

/*-----------------------*
 *   GENERAL FUNCTIONS   *
 *-----------------------*/

/**
 * @brief Create a new trie
 *
 * @param   alpha_map   : the alphabet set for the trie
 *
 * @return a pointer to the newly created trie, NULL on failure
 *
 * Create a new empty trie object based on the given @a alpha_map alphabet
 * set. The trie contents can then be added and deleted with trie_store() and
 * trie_delete() respectively.
 *
 * The created object must be freed with trie_free().
 */
Trie *
trie_new (const AlphaMap *alpha_map)
{
    Trie *trie;

    trie = (Trie *) malloc (sizeof (Trie));
    if (!trie)
        return NULL;

    trie->alpha_map = alpha_map_clone (alpha_map);
    if (!trie->alpha_map)
        goto exit_trie_created;

    trie->da = da_new ();
    if (!trie->da)
        goto exit_alpha_map_created;

    trie->tail = tail_new ();
    if (!trie->tail)
        goto exit_da_created;
 
    trie->is_dirty = TRUE;
    return trie;

exit_da_created:
    da_free (trie->da);
exit_alpha_map_created:
    alpha_map_free (trie->alpha_map);
exit_trie_created:
    free (trie);
    return NULL;
}

/**
 * @brief Create a new trie by loading from a file
 *
 * @param path  : the path to the file
 *
 * @return a pointer to the created trie, NULL on failure
 *
 * Create a new trie and initialize its contents by loading from the file at
 * given @a path.
 *
 * The created object must be freed with trie_free().
 */
Trie *
trie_new_from_file (const char *path)
{
    Trie       *trie;
    FILE       *trie_file;

    trie_file = fopen (path, "r");
    if (!trie_file)
        return NULL;

    trie = trie_fread (trie_file);
    fclose (trie_file);
    return trie;
}

/**
 * @brief Create a new trie by reading from an open file
 *
 * @param file  : the handle of the open file
 *
 * @return a pointer to the created trie, NULL on failure
 *
 * Create a new trie and initialize its contents by reading from the open
 * @a file. After reading, the file pointer is left at the end of the trie data.
 * This can be useful for reading embedded trie index as part of a file data.
 *
 * The created object must be freed with trie_free().
 *
 * Available since: 0.2.4
 */
Trie *
trie_fread (FILE *file)
{
    Trie       *trie;

    trie = (Trie *) malloc (sizeof (Trie));
    if (!trie)
        return NULL;

    if (NULL == (trie->alpha_map = alpha_map_fread_bin (file)))
        goto exit_trie_created;
    if (NULL == (trie->da   = da_fread (file)))
        goto exit_alpha_map_created;
    if (NULL == (trie->tail = tail_fread (file)))
        goto exit_da_created;

    trie->is_dirty = FALSE;
    return trie;

exit_da_created:
    da_free (trie->da);
exit_alpha_map_created:
    alpha_map_free (trie->alpha_map);
exit_trie_created:
    free (trie);
    return NULL;
}

/**
 * @brief Free a trie object
 *
 * @param trie  : the trie object to free
 *
 * Destruct the @a trie and free its allocated memory.
 */
void
trie_free (Trie *trie)
{
    alpha_map_free (trie->alpha_map);
    da_free (trie->da);
    tail_free (trie->tail);
    free (trie);
}

/**
 * @brief Save a trie to file
 *
 * @param trie  : the trie
 *
 * @param path  : the path to the file
 *
 * @return 0 on success, non-zero on failure
 *
 * Create a new file at the given @a path and write @a trie data to it.
 * If @a path already exists, its contents will be replaced.
 */
int
trie_save (Trie *trie, const char *path)
{
    FILE *file;
    int   res = 0;

    file = fopen (path, "w+");
    if (!file)
        return -1;

    res = trie_fwrite (trie, file);
    fclose (file);
    return res;
}

/**
 * @brief Write trie data to an open file
 *
 * @param trie  : the trie
 *
 * @param file  : the open file
 *
 * @return 0 on success, non-zero on failure
 *
 * Write @a trie data to @a file which is opened for writing.
 * After writing, the file pointer is left at the end of the trie data.
 * This can be useful for embedding trie index as part of a file data.
 *
 * Available since: 0.2.4
 */
int
trie_fwrite (Trie *trie, FILE *file)
{
    if (alpha_map_fwrite_bin (trie->alpha_map, file) != 0)
        return -1;

    if (da_fwrite (trie->da, file) != 0)
        return -1;

    if (tail_fwrite (trie->tail, file) != 0)
        return -1;

    trie->is_dirty = FALSE;

    return 0;
}

/**
 * @brief Check pending changes
 *
 * @param trie  : the trie object
 *
 * @return TRUE if there are pending changes, FALSE otherwise
 *
 * Check if the @a trie is dirty with some pending changes and needs saving
 * to synchronize with the file.
 */
Bool
trie_is_dirty (const Trie *trie)
{
    return trie->is_dirty;
}


/*------------------------------*
 *   GENERAL QUERY OPERATIONS   *
 *------------------------------*/

/**
 * @brief Retrieve an entry from trie
 *
 * @param trie   : the trie
 * @param key    : the key for the entry to retrieve
 * @param o_data : the storage for storing the entry data on return
 *
 * @return boolean value indicating the existence of the entry.
 *
 * Retrieve an entry for the given @a key from @a trie. On return,
 * if @a key is found and @a o_data is not NULL, @a *o_data is set
 * to the data associated to @a key.
 */
Bool
trie_retrieve (const Trie *trie, const AlphaChar *key, TrieData *o_data)
{
    TrieIndex        s;
    short            suffix_idx;
    const AlphaChar *p;

    /* walk through branches */
    s = da_get_root (trie->da);
    for (p = key; !trie_da_is_separate (trie->da, s); p++) {
        if (!da_walk (trie->da, &s,
                      alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            return FALSE;
        }
        if (0 == *p)
            break;
    }

    /* walk through tail */
    s = trie_da_get_tail_index (trie->da, s);
    suffix_idx = 0;
    for ( ; ; p++) {
        if (!tail_walk_char (trie->tail, s, &suffix_idx,
                             alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            return FALSE;
        }
        if (0 == *p)
            break;
    }

    /* found, set the val and return */
    if (o_data)
        *o_data = tail_get_data (trie->tail, s);
    return TRUE;
}

/**
 * @brief Store a value for an entry to trie
 *
 * @param trie  : the trie
 * @param key   : the key for the entry to retrieve
 * @param data  : the data associated to the entry
 *
 * @return boolean value indicating the success of the process
 *
 * Store a @a data for the given @a key in @a trie. If @a key does not 
 * exist in @a trie, it will be appended. If it does, its current data will
 * be overwritten.
 */
Bool
trie_store (Trie *trie, const AlphaChar *key, TrieData data)
{
    return trie_store_conditionally (trie, key, data, TRUE);
}

/**
 * @brief Store a value for an entry to trie only if the key is not present
 *
 * @param trie  : the trie
 * @param key   : the key for the entry to retrieve
 * @param data  : the data associated to the entry
 *
 * @return boolean value indicating the success of the process
 *
 * Store a @a data for the given @a key in @a trie. If @a key does not 
 * exist in @a trie, it will be appended. If it does, the function will
 * return failure and the existing value will not be touched.
 *
 * This can be useful for multi-thread applications, as race condition
 * can be avoided.
 *
 * Available since: 0.2.4
 */
Bool
trie_store_if_absent (Trie *trie, const AlphaChar *key, TrieData data)
{
    return trie_store_conditionally (trie, key, data, FALSE);
}

static Bool
trie_store_conditionally (Trie            *trie,
                          const AlphaChar *key,
                          TrieData         data,
                          Bool             is_overwrite)
{
    TrieIndex        s, t;
    short            suffix_idx;
    const AlphaChar *p, *sep;

    /* walk through branches */
    s = da_get_root (trie->da);
    for (p = key; !trie_da_is_separate (trie->da, s); p++) {
        if (!da_walk (trie->da, &s,
                      alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            TrieChar *key_str;
            Bool      res;

            key_str = alpha_map_char_to_trie_str (trie->alpha_map, p);
            res = trie_branch_in_branch (trie, s, key_str, data);
            free (key_str);

            return res;
        }
        if (0 == *p)
            break;
    }

    /* walk through tail */
    sep = p;
    t = trie_da_get_tail_index (trie->da, s);
    suffix_idx = 0;
    for ( ; ; p++) {
        if (!tail_walk_char (trie->tail, t, &suffix_idx,
                             alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            TrieChar *tail_str;
            Bool      res;

            tail_str = alpha_map_char_to_trie_str (trie->alpha_map, sep);
            res = trie_branch_in_tail (trie, s, tail_str, data);
            free (tail_str);

            return res;
        }
        if (0 == *p)
            break;
    }

    /* duplicated key, overwrite val if flagged */
    if (!is_overwrite) {
        return FALSE;
    }
    tail_set_data (trie->tail, t, data);
    trie->is_dirty = TRUE;
    return TRUE;
}

static Bool
trie_branch_in_branch (Trie           *trie,
                       TrieIndex       sep_node,
                       const TrieChar *suffix,
                       TrieData        data)
{
    TrieIndex new_da, new_tail;

    new_da = da_insert_branch (trie->da, sep_node, *suffix);
    if (TRIE_INDEX_ERROR == new_da)
        return FALSE;

    if ('\0' != *suffix)
        ++suffix;

    new_tail = tail_add_suffix (trie->tail, suffix);
    tail_set_data (trie->tail, new_tail, data);
    trie_da_set_tail_index (trie->da, new_da, new_tail);

    trie->is_dirty = TRUE;
    return TRUE;
}

static Bool
trie_branch_in_tail   (Trie           *trie,
                       TrieIndex       sep_node,
                       const TrieChar *suffix,
                       TrieData        data)
{
    TrieIndex       old_tail, old_da, s;
    const TrieChar *old_suffix, *p;

    /* adjust separate point in old path */
    old_tail = trie_da_get_tail_index (trie->da, sep_node);
    old_suffix = tail_get_suffix (trie->tail, old_tail);
    if (!old_suffix)
        return FALSE;

    for (p = old_suffix, s = sep_node; *p == *suffix; p++, suffix++) {
        TrieIndex t = da_insert_branch (trie->da, s, *p);
        if (TRIE_INDEX_ERROR == t)
            goto fail;
        s = t;
    }

    old_da = da_insert_branch (trie->da, s, *p);
    if (TRIE_INDEX_ERROR == old_da)
        goto fail;

    if ('\0' != *p)
        ++p;
    tail_set_suffix (trie->tail, old_tail, p);
    trie_da_set_tail_index (trie->da, old_da, old_tail);

    /* insert the new branch at the new separate point */
    return trie_branch_in_branch (trie, s, suffix, data);

fail:
    /* failed, undo previous insertions and return error */
    da_prune_upto (trie->da, sep_node, s);
    trie_da_set_tail_index (trie->da, sep_node, old_tail);
    return FALSE;
}

/**
 * @brief Delete an entry from trie
 *
 * @param trie  : the trie
 * @param key   : the key for the entry to delete
 *
 * @return boolean value indicating whether the key exists and is removed
 *
 * Delete an entry for the given @a key from @a trie.
 */
Bool
trie_delete (Trie *trie, const AlphaChar *key)
{
    TrieIndex        s, t;
    short            suffix_idx;
    const AlphaChar *p;

    /* walk through branches */
    s = da_get_root (trie->da);
    for (p = key; !trie_da_is_separate (trie->da, s); p++) {
        if (!da_walk (trie->da, &s,
                      alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            return FALSE;
        }
        if (0 == *p)
            break;
    }

    /* walk through tail */
    t = trie_da_get_tail_index (trie->da, s);
    suffix_idx = 0;
    for ( ; ; p++) {
        if (!tail_walk_char (trie->tail, t, &suffix_idx,
                             alpha_map_char_to_trie (trie->alpha_map, *p)))
        {
            return FALSE;
        }
        if (0 == *p)
            break;
    }

    tail_delete (trie->tail, t);
    da_set_base (trie->da, s, TRIE_INDEX_ERROR);
    da_prune (trie->da, s);

    trie->is_dirty = TRUE;
    return TRUE;
}

typedef struct {
    const Trie     *trie;
    TrieEnumFunc    enum_func;
    void           *user_data;
} _TrieEnumData;

static Bool
trie_da_enum_func (const TrieChar *key, TrieIndex sep_node, void *user_data)
{
    _TrieEnumData  *enum_data;
    TrieIndex       t;
    const TrieChar *suffix;
    AlphaChar      *full_key, *p;
    Bool            ret;

    enum_data = (_TrieEnumData *) user_data;

    t = trie_da_get_tail_index (enum_data->trie->da, sep_node);
    suffix = tail_get_suffix (enum_data->trie->tail, t);

    full_key = (AlphaChar *) malloc ((strlen ((const char *)key)
                                      + strlen ((const char *)suffix) + 1)
                                     * sizeof (AlphaChar));
    for (p = full_key; *key; p++, key++) {
        *p = alpha_map_trie_to_char (enum_data->trie->alpha_map, *key);
    }
    for ( ; *suffix; p++, suffix++) {
        *p = alpha_map_trie_to_char (enum_data->trie->alpha_map, *suffix);
    }
    *p = 0;

    ret = (*enum_data->enum_func) (full_key,
                                   tail_get_data (enum_data->trie->tail, t),
                                   enum_data->user_data);

    free (full_key);
    return ret;
}

/**
 * @brief Enumerate entries in trie
 *
 * @param trie       : the trie
 * @param enum_func  : the callback function to be called on each key
 * @param user_data  : user-supplied data to send as an argument to @a enum_func
 *
 * @return boolean value indicating whether all the keys are visited
 *
 * Enumerate all entries in trie. For each entry, the user-supplied 
 * @a enum_func callback function is called, with the entry key and data.
 * Returning FALSE from such callback will stop enumeration and return FALSE.
 */
Bool
trie_enumerate (const Trie *trie, TrieEnumFunc enum_func, void *user_data)
{
    _TrieEnumData   enum_data;

    enum_data.trie      = trie;
    enum_data.enum_func = enum_func;
    enum_data.user_data = user_data;

    return da_enumerate (trie->da, trie_da_enum_func, &enum_data);
}


/*-------------------------------*
 *   STEPWISE QUERY OPERATIONS   *
 *-------------------------------*/

/**
 * @brief Get root state of a trie
 *
 * @param trie : the trie
 *
 * @return the root state of the trie
 *
 * Get root state of @a trie, for stepwise walking.
 *
 * The returned state is allocated and must be freed with trie_state_free()
 */
TrieState *
trie_root (const Trie *trie)
{
    return trie_state_new (trie, da_get_root (trie->da), 0, FALSE);
}

/*----------------*
 *   TRIE STATE   *
 *----------------*/

static TrieState *
trie_state_new (const Trie *trie,
                TrieIndex   index,
                short       suffix_idx,
                short       is_suffix)
{
    TrieState *s;

    s = (TrieState *) malloc (sizeof (TrieState));
    if (!s)
        return NULL;

    s->trie       = trie;
    s->index      = index;
    s->suffix_idx = suffix_idx;
    s->is_suffix  = is_suffix;

    return s;
}

/**
 * @brief Copy trie state to another
 *
 * @param dst  : the destination state
 * @param src  : the source state
 *
 * Copy trie state data from @a src to @a dst. All existing data in @a dst
 * is overwritten.
 */
void
trie_state_copy (TrieState *dst, const TrieState *src)
{
    /* May be deep copy if necessary, not the case for now */
    *dst = *src;
}

/**
 * @brief Clone a trie state
 *
 * @param s    : the state to clone
 *
 * @return an duplicated instance of @a s
 *
 * Make a copy of trie state.
 *
 * The returned state is allocated and must be freed with trie_state_free()
 */
TrieState *
trie_state_clone (const TrieState *s)
{
    return trie_state_new (s->trie, s->index, s->suffix_idx, s->is_suffix);
}

/**
 * @brief Free a trie state
 *
 * @param s    : the state to free
 *
 * Free the trie state.
 */
void
trie_state_free (TrieState *s)
{
    free (s);
}

/**
 * @brief Rewind a trie state
 *
 * @param s    : the state to rewind
 *
 * Put the state at root.
 */
void
trie_state_rewind (TrieState *s)
{
    s->index      = da_get_root (s->trie->da);
    s->is_suffix  = FALSE;
}

/**
 * @brief Walk the trie from the state
 *
 * @param s    : current state
 * @param c    : key character for walking
 *
 * @return boolean value indicating the success of the walk
 *
 * Walk the trie stepwise, using a given character @a c.
 * On return, the state @a s is updated to the new state if successfully walked.
 */
Bool
trie_state_walk (TrieState *s, AlphaChar c)
{
    TrieChar tc = alpha_map_char_to_trie (s->trie->alpha_map, c);

    if (!s->is_suffix) {
        Bool ret;

        ret = da_walk (s->trie->da, &s->index, tc);

        if (ret && trie_da_is_separate (s->trie->da, s->index)) {
            s->index = trie_da_get_tail_index (s->trie->da, s->index);
            s->suffix_idx = 0;
            s->is_suffix = TRUE;
        }

        return ret;
    } else {
        return tail_walk_char (s->trie->tail, s->index, &s->suffix_idx, tc);
    }
}

/**
 * @brief Test walkability of character from state
 *
 * @param s    : the state to check
 * @param c    : the input character
 *
 * @return boolean indicating walkability
 *
 * Test if there is a transition from state @a s with input character @a c.
 */
Bool
trie_state_is_walkable (const TrieState *s, AlphaChar c)
{
    TrieChar tc = alpha_map_char_to_trie (s->trie->alpha_map, c);

    if (!s->is_suffix)
        return da_is_walkable (s->trie->da, s->index, tc);
    else 
        return tail_is_walkable_char (s->trie->tail, s->index, s->suffix_idx,
                                      tc);
}

/**
 * @brief Check for single path
 *
 * @param s    : the state to check
 *
 * @return boolean value indicating whether it is in a single path
 *
 * Check if the given state is in a single path, that is, there is no other
 * branch from it to leaf.
 */
Bool
trie_state_is_single (const TrieState *s)
{
    return s->is_suffix;
}

/**
 * @brief Get data from leaf state
 *
 * @param s    : a leaf state
 *
 * @return the data associated with the leaf state @a s,
 *         or TRIE_DATA_ERROR if @a s is not a leaf state
 *
 * Get value from a leaf state of trie. Getting value from a non-leaf state
 * will result in TRIE_DATA_ERROR.
 */
TrieData
trie_state_get_data (const TrieState *s)
{
    return s->is_suffix ? tail_get_data (s->trie->tail, s->index)
                        : TRIE_DATA_ERROR;
}

/*
vi:ts=4:ai:expandtab
*/
