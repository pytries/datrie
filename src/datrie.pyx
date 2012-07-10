# cython: profile=True
"""
Cython wrapper for libdatrie.
"""

from libc.stdlib cimport malloc, free
from libc cimport stdio
from libc cimport string
cimport cdatrie

import sys
import itertools

class DatrieError(Exception):
    pass


def new(alphabet=None, ranges=None, AlphaMap alpha_map=None):
    """
    Creates a new Trie.

    For efficiency trie needs to know what unicode symbols
    it should be able to store so this constructor requires
    either ``alphabet`` (a string/iterable with all allowed characters),
    ``ranges`` (a list of (begin, end) pairs, e.g. [('a', 'z')])
    or ``alpha_map`` (:class:`datrie.AlphaMap` instance).
    """
    if alpha_map is None:
        alpha_map = AlphaMap(alphabet, ranges)
    return Trie(path=None, alpha_map=alpha_map)


def load(path):
    """
    Loads a Trie from file.
    """
    return Trie(path=path, alpha_map=None)

RAISE_KEY_ERROR=object()

cdef class Trie:
    cdef cdatrie.Trie *_c_trie

    def __init__(self, path=None, AlphaMap alpha_map=None):
        if self._c_trie is not NULL:
            return
        if alpha_map is not None:
            self._c_trie = cdatrie.trie_new(alpha_map._c_alpha_map)
            if self._c_trie is NULL:
                raise MemoryError()
        else:
            self._c_trie = _load_from_file(path)

    def __dealloc__(self):
        if self._c_trie is not NULL:
            cdatrie.trie_free(self._c_trie)

    cpdef bint is_dirty(self):
        """
        Returns True if the trie is dirty with some pending changes
        and needs saving to synchronize with the file.
        """
        return cdatrie.trie_is_dirty(self._c_trie)

    def __setitem__(self, unicode key, cdatrie.TrieData value):
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            cdatrie.trie_store(self._c_trie, c_key, value)
        finally:
            free(c_key)

    def __getitem__(self, unicode key):
        cdef cdatrie.TrieData data = 0
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)

        try:
            found = cdatrie.trie_retrieve(self._c_trie, c_key, &data)
        finally:
            free(c_key)

        if not found:
            raise KeyError(key)
        return data

    def __contains__(self, unicode key):
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            return cdatrie.trie_retrieve(self._c_trie, c_key, NULL)
        finally:
            free(c_key)

    def __delitem__(self, unicode key):
        self._delete(key)

    cpdef bint _delete(self, unicode key):
        """
        Deletes an entry for the given key from the trie. Returns
        boolean value indicating whether the key exists and is removed.
        """
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            return cdatrie.trie_delete(self._c_trie, c_key)
        finally:
            free(c_key)

    def iter_prefixes(self, unicode key):
        '''
        Returns an iterator over the keys of this trie that are prefixes
        of ``key``.
        '''
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        if state == NULL:
            raise MemoryError()

        cdef int index = 1
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    return
                if cdatrie.trie_state_is_terminal(state):
                    yield key[:index]
                index += 1
        finally:
            cdatrie.trie_state_free(state)

    def iter_prefix_items(self, unicode key):
        '''
        Returns an iterator over the items (``(key,value)`` tuples)
        of this trie that are associated with keys that are prefixes of ``key``.
        '''
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        cdef cdatrie.TrieState* tmp_state = cdatrie.trie_state_clone(state)

        if state == NULL or tmp_state == NULL:
            raise MemoryError()

        cdef int index = 1
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    return
                if cdatrie.trie_state_is_terminal(state): # word is found
                    yield key[:index], _terminal_state_data(state, tmp_state)
                index += 1
        finally:
            cdatrie.trie_state_free(state)
            cdatrie.trie_state_free(tmp_state)


    def prefixes(self, unicode key):
        '''
        Returns a list with keys of this trie that are prefixes of ``key``.
        '''
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        if state == NULL:
            raise MemoryError()

        cdef list result = []
        cdef int index = 1
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    break
                if cdatrie.trie_state_is_terminal(state):
                    result.append(key[:index])
                index += 1
            return result
        finally:
            cdatrie.trie_state_free(state)


    def prefix_items(self, unicode key):
        '''
        Returns a list of the items (``(key,value)`` tuples)
        of this trie that are associated with keys that are
        prefixes of ``key``.
        '''
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        cdef cdatrie.TrieState* tmp_state = cdatrie.trie_state_clone(state)

        if state == NULL or tmp_state == NULL:
            raise MemoryError()

        cdef list result = []
        cdef int index = 1
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    break
                if cdatrie.trie_state_is_terminal(state): # word is found
                    result.append(
                        (key[:index],
                         _terminal_state_data(state, tmp_state))
                    )
                index += 1
            return result
        finally:
            cdatrie.trie_state_free(state)
            cdatrie.trie_state_free(tmp_state)

    def longest_prefix(self, unicode key, default=RAISE_KEY_ERROR):
        """
        Returns the longest key in this trie that is a prefix of ``key``.

        If the trie doesn't contain any prefix of ``key``:
          - if ``default`` is given, returns it,
          - otherwise raises ``KeyError``.
        """
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        if state == NULL:
            raise MemoryError()

        cdef int index = 0
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    if cdatrie.trie_state_is_terminal(state):
                        return key[:index]
                    else:
                        if default is RAISE_KEY_ERROR:
                            raise KeyError(key)
                        return default
                index += 1
            if cdatrie.trie_state_is_terminal(state):
                return key
            if default is RAISE_KEY_ERROR:
                raise KeyError(key)
        finally:
            cdatrie.trie_state_free(state)


    def longest_prefix_item(self, unicode key, default=RAISE_KEY_ERROR):
        """
        Return the item (``(key,value)`` tuple) associated with the longest
        key in this trie that is a prefix of ``key``.

        If the trie doesn't contain any prefix of ``key``:
          - if ``default`` is given, returns it,
          - otherwise raises ``KeyError``.
        """
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        cdef cdatrie.TrieState* tmp_state = cdatrie.trie_state_clone(state)

        if state == NULL or tmp_state == NULL:
            raise MemoryError()

        cdef int index = 0
        try:
            for char in key:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    if cdatrie.trie_state_is_terminal(state):
                        return key[:index], _terminal_state_data(state, tmp_state)
                    else:
                        if default is RAISE_KEY_ERROR:
                            raise KeyError(key)
                        return default
                index += 1
            if cdatrie.trie_state_is_terminal(state):
                return key
            if default is RAISE_KEY_ERROR:
                raise KeyError(key)
        finally:
            cdatrie.trie_state_free(state)
            cdatrie.trie_state_free(tmp_state)


    def has_keys_with_prefix(self, unicode prefix):
        """
        Returns True if any key in the trie begins with ``prefix``.
        """
        cdef cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
        if state == NULL:
            raise MemoryError()
        try:
            for char in prefix:
                if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                    return False
            return True
        finally:
            cdatrie.trie_state_free(state)


    def items(self):
        # XXX: this implementation is ugly and inefficient
        _items = []
        def callback(key, value):
            _items.append((key, value))
            return True
        self._enumerate(callback)
        return _items

    def keys(self):
        # XXX: this implementation is ugly and inefficient
        _keys = []
        def callback(key, value):
            _keys.append(key)
            return True
        self._enumerate(callback)
        return _keys

    def values(self):
        # XXX: this implementation is ugly and inefficient
        _values = []
        def callback(key, value):
            _values.append(value)
            return True
        self._enumerate(callback)
        return _values


    def __len__(self):
        # XXX: this is very slow
        cdef int counter=0
        cdatrie.trie_enumerate(
            self._c_trie,
            _trie_counter,
            &counter
        )
        return counter

    cpdef _enumerate(self, callback):
        """
        Enumerates all entries in trie. For each entry, the user-supplied
        callback function is called, with the entry key and data.
        Return True from the callback to continue the enumeration,
        returning False from such callback will stop enumeration.
        """
        return cdatrie.trie_enumerate(
            self._c_trie,
            trie_enum_helper,
            <void*> callback
        )

    def save(self, path):
        str_path = path.encode(sys.getfilesystemencoding())
        cdef char* c_path = str_path
        cdef int res = cdatrie.trie_save(self._c_trie, c_path)
        if res == -1:
            raise IOError("Can't write to file")


cdef cdatrie.TrieData _terminal_state_data(cdatrie.TrieState* state, cdatrie.TrieState* tmp_state):
    """
    Wrapper for cdatrie.trie_state_get_data that
    handle non-leaf nodes.
    """
    if cdatrie.trie_state_is_single(state): # leaf
        return cdatrie.trie_state_get_data(state)
    else: # non-leaf terminal, data is not available here
        cdatrie.trie_state_copy(tmp_state, state)
        cdatrie.trie_state_walk(tmp_state, cdatrie.TRIE_CHAR_TERM)
        return cdatrie.trie_state_get_data(tmp_state)


cdef class AlphaMap:
    """
    Alphabet map.

    For sparse data compactness, the trie alphabet set should
    be continuous, but that is usually not the case in general
    character sets. Therefore, a map between the input character
    and the low-level alphabet set for the trie is created in the
    middle. You will have to define your input character set by
    listing their continuous ranges of character codes creating a
    trie. Then, each character will be automatically assigned
    internal codes of continuous values.
    """

    cdef cdatrie.AlphaMap *_c_alpha_map

    def __cinit__(self):
        self._c_alpha_map = cdatrie.alpha_map_new()
        if self._c_alpha_map is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._c_alpha_map is not NULL:
            cdatrie.alpha_map_free(self._c_alpha_map)

    def __init__(self, alphabet=None, ranges=None):
        if ranges is not None:
            for range in ranges:
                self.add_range(*range)

        if alphabet is not None:
            self.add_alphabet(alphabet)

    def add_alphabet(self, alphabet):
        """
        Adds all chars from iterable to the alphabet set.
        """
        for begin, end in alphabet_to_ranges(alphabet):
            self._add_range(begin, end)

    def add_range(self, begin, end):
        """
        Add a range of character codes from ``begin`` to ``end``
        to the alphabet set.

        ``begin`` - the first character of the range;
        ``end`` - the last character of the range.
        """
        self._add_range(ord(begin), ord(end))

    cpdef _add_range(self, cdatrie.AlphaChar begin, cdatrie.AlphaChar end):
        if begin > end:
            raise DatrieError('range begin > end')
        code = cdatrie.alpha_map_add_range(self._c_alpha_map, begin, end)
        if code != 0:
            raise MemoryError()

cdef (cdatrie.AlphaChar*) new_alpha_char_from_unicode(unicode txt):
    """
    Converts Python unicode string to libdatrie's AlphaChar* format.
    libdatrie wants null-terminated array of 4-byte LE symbols.
    """
    cdef int txt_len = len(txt)
    cdef int size = (txt_len + 1) * sizeof(cdatrie.AlphaChar)

    # allocate buffer
    cdef cdatrie.AlphaChar* data = <cdatrie.AlphaChar*> malloc(size)
    if data is NULL:
        raise MemoryError()

    # Copy text contents to buffer.
    # XXX: is it safe? The safe alternative is to decode txt
    # to utf32_le and then use memcpy to copy the content:
    #
    #    py_str = txt.encode('utf_32_le')
    #    cdef char* c_str = py_str
    #    string.memcpy(data, c_str, size-1)
    #
    # but the following is much (say 10x) faster and this
    # function is really in a hot spot.
    cdef int i = 0
    for char in txt:
        data[i] = <cdatrie.AlphaChar> char
        i+=1

    # Buffer must be null-terminated (last 4 bytes must be zero).
    data[txt_len] = 0
    return data

cdef unicode unicode_from_alpha_char(cdatrie.AlphaChar* key, int len=0):
    """
    Converts libdatrie's AlphaChar* to Python unicode.
    """
    cdef int length = len
    if length == 0:
        length = cdatrie.alpha_char_strlen(key)*sizeof(cdatrie.AlphaChar)
    cdef char* c_str = <char*> key
    return c_str[:length].decode('utf_32_le')


cdef bint trie_enum_helper(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *py_func):
    cdef unicode py_key = unicode_from_alpha_char(key)
    cdef int py_data = <int>key_data
    res = (<object>py_func)(py_key, py_data)
    return res

cdef bint _trie_counter(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *counter):
    (<int *>counter)[0] += 1
    return 1


def to_ranges(lst):
    """
    Converts a list of numbers to a list of ranges::

    >>> numbers = [1,2,3,5,6]
    >>> list(to_ranges(numbers))
    [(1, 3), (5, 6)]
    """
    for a, b in itertools.groupby(enumerate(lst), lambda t: t[1] - t[0]):
        b = list(b)
        yield b[0][1], b[-1][1]

def alphabet_to_ranges(alphabet):
    for begin, end in to_ranges(sorted(map(ord, iter(alphabet)))):
        yield begin, end


cdef (cdatrie.Trie*) _load_from_file(path) except NULL:
    str_path = path.encode(sys.getfilesystemencoding())
    cdef char* c_path = str_path
    cdef cdatrie.Trie* c_trie

    c_trie = cdatrie.trie_new_from_file(c_path)
    if c_trie is NULL:
        raise DatrieError()

    return c_trie

