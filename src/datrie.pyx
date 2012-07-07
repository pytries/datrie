from libc.stdlib cimport malloc, free
from libc cimport stdio
from libc cimport string

cimport cdatrie
import sys

class DatrieError(Exception):
    pass

cdef class AlphaMap:
    cdef cdatrie.AlphaMap *_c_alpha_map

    def __cinit__(self):
        self._c_alpha_map = cdatrie.alpha_map_new()
        if self._c_alpha_map is NULL:
            raise MemoryError()

    def __dealloc__(self):
        if self._c_alpha_map is not NULL:
            cdatrie.alpha_map_free(self._c_alpha_map)

    def add_alphabet(self, alphabet):
        """
        Adds all chars from iterable to the alphabet set.
        """
        for symb in alphabet:
            self.add_range(symb, symb)

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


cdef (cdatrie.Trie*) _load_from_file(path) except NULL:
    str_path = path.encode(sys.getfilesystemencoding())
    cdef char* c_path = str_path
    cdef cdatrie.Trie* c_trie

    c_trie = cdatrie.trie_new_from_file(c_path)
    if c_trie is NULL:
        raise DatrieError()

    return c_trie

cdef (cdatrie.AlphaChar*) new_alpha_char_from_unicode(unicode txt):
    txt_len = len(txt)
    cdef int size = (txt_len+1) * sizeof(cdatrie.AlphaChar)

    py_str = txt.encode('utf_32_le')
    cdef char* c_str = py_str

    cdef cdatrie.AlphaChar* data = <cdatrie.AlphaChar*> malloc(size)
    if data is NULL:
        raise MemoryError()
    string.memcpy(data, c_str, size)
    data[txt_len] = 0
    return data


def create(AlphaMap alpha_map):
    """
    Creates a new Trie using ``alpha_map``.
    """
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
        return cdatrie.trie_is_dirty(self._c_trie)

    def __setitem__(self, unicode key, cdatrie.TrieData value):
        cdef cdatrie.AlphaChar* chars = new_alpha_char_from_unicode(key)
        try:
            cdatrie.trie_store(self._c_trie, chars, value)
        finally:
            free(chars)

    def __getitem__(self, unicode key):
        cdef cdatrie.TrieData data = 0
        cdef cdatrie.AlphaChar* chars = new_alpha_char_from_unicode(key)

        try:
            found = cdatrie.trie_retrieve(self._c_trie, chars, &data)
        finally:
            free(chars)

        if not found:
            raise KeyError()
        return data

    def __contains__(self, unicode key):
        cdef cdatrie.AlphaChar* chars = new_alpha_char_from_unicode(key)
        try:
            return cdatrie.trie_retrieve(self._c_trie, chars, NULL)
        finally:
            free(chars)

    def save(self, path):
        str_path = path.encode(sys.getfilesystemencoding())
        cdef char* c_path = str_path
        cdef int res = cdatrie.trie_save(self._c_trie, c_path)
        if res == -1:
            raise IOError("Can't write to file")
