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
            raise KeyError()
        return data

    def __contains__(self, unicode key):
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            return cdatrie.trie_retrieve(self._c_trie, c_key, NULL)
        finally:
            free(c_key)

    def save(self, path):
        str_path = path.encode(sys.getfilesystemencoding())
        cdef char* c_path = str_path
        cdef int res = cdatrie.trie_save(self._c_trie, c_path)
        if res == -1:
            raise IOError("Can't write to file")


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

