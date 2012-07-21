# cython: profile=False
"""
Cython wrapper for libdatrie.
"""

from libc.stdlib cimport malloc, free
from libc cimport stdio
from libc cimport string
cimport stdio_ext
cimport cdatrie

import warnings
import sys
import itertools
import pickle

class DatrieError(Exception):
    pass


RAISE_KEY_ERROR = object()
RERAISE_KEY_ERROR = object()
DELETED_OBJECT = object()



cdef class BaseTrie:
    """
    Wrapper for libdatrie's trie.

    Keys are unicode strings, values are integers 0 <= x <= 2147483647.
    """

    cdef cdatrie.Trie *_c_trie

    def __init__(self, alphabet=None, ranges=None, AlphaMap alpha_map=None, _create=True):
        """
        For efficiency trie needs to know what unicode symbols
        it should be able to store so this constructor requires
        either ``alphabet`` (a string/iterable with all allowed characters),
        ``ranges`` (a list of (begin, end) pairs, e.g. [('a', 'z')])
        or ``alpha_map`` (:class:`datrie.AlphaMap` instance).
        """
        if self._c_trie is not NULL:
            return

        if not _create:
            return

        if alphabet is None and ranges is None and alpha_map is None:
            raise ValueError("Please provide alphabet, ranges or alpha_map argument.")

        if alpha_map is None:
            alpha_map = AlphaMap(alphabet, ranges)

        self._c_trie = cdatrie.trie_new(alpha_map._c_alpha_map)
        if self._c_trie is NULL:
            raise MemoryError()


    def __dealloc__(self):
        if self._c_trie is not NULL:
            cdatrie.trie_free(self._c_trie)

    cpdef bint is_dirty(self):
        """
        Returns True if the trie is dirty with some pending changes
        and needs saving to synchronize with the file.
        """
        return cdatrie.trie_is_dirty(self._c_trie)

    def save(self, path):
        """
        Saves this trie.
        """
        with open(path, "wb", 0) as f:
            self.write(f)

    def write(self, f):
        """
        Writes a trie to a file. File-like objects without real
        file descriptors are not supported.
        """
        f.flush()

        cdef stdio.FILE* f_ptr = stdio_ext.fdopen(f.fileno(), "w")
        if f_ptr == NULL:
            raise IOError("Can't open file descriptor")

        cdef int res = cdatrie.trie_fwrite(self._c_trie, f_ptr)
        if res == -1:
            raise IOError("Can't write to file")

        stdio.fflush(f_ptr)


    @classmethod
    def load(cls, path):
        """
        Loads a trie from file.
        """
        with open(path, "rb", 0) as f:
            return cls.read(f)

    @classmethod
    def read(cls, f):
        """
        Creates a new Trie by reading it from file.
        File-like objects without real file descriptors are not supported.

        # XXX: does it work properly in subclasses?
        """
        cdef BaseTrie trie = cls(_create=False)
        trie._c_trie = _load_from_file(f)
        return trie

    def __setitem__(self, unicode key, cdatrie.TrieData value):
        self._setitem(key, value)

    cdef void _setitem(self, unicode key, cdatrie.TrieData value):
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            cdatrie.trie_store(self._c_trie, c_key, value)
        finally:
            free(c_key)

    def __getitem__(self, unicode key):
        return self._getitem(key)

    cdef cdatrie.TrieData _getitem(self, unicode key) except -1:
        cdef cdatrie.TrieData data
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
        if not self._delitem(key):
            raise KeyError(key)

    cpdef bint _delitem(self, unicode key):
        """
        Deletes an entry for the given key from the trie. Returns
        boolean value indicating whether the key exists and is removed.
        """
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        try:
            return cdatrie.trie_delete(self._c_trie, c_key)
        finally:
            free(c_key)

    def __len__(self):
        # XXX: this is very slow
        cdef int counter=0
        cdatrie.trie_enumerate(
            self._c_trie,
            _trie_counter,
            &counter
        )
        return counter

    def setdefault(self, unicode key, cdatrie.TrieData value):
        return self._setdefault(key, value)

    cdef cdatrie.TrieData _setdefault(self, unicode key, cdatrie.TrieData value):
        cdef cdatrie.AlphaChar* c_key = new_alpha_char_from_unicode(key)
        cdef cdatrie.TrieData data

        try:
            found = cdatrie.trie_retrieve(self._c_trie, c_key, &data)
            if found:
                return data
            else:
                cdatrie.trie_store(self._c_trie, c_key, value)
                return value
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
        return self._prefix_items(key)

    cdef list _prefix_items(self, unicode key):
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
            return default
        finally:
            cdatrie.trie_state_free(state)


    def longest_prefix_item(self, unicode key, default=RAISE_KEY_ERROR):
        """
        Returns the item (``(key,value)`` tuple) associated with the longest
        key in this trie that is a prefix of ``key``.

        If the trie doesn't contain any prefix of ``key``:
          - if ``default`` is given, returns it,
          - otherwise raises ``KeyError``.
        """
        return self._longest_prefix_item(key, default)

    cdef _longest_prefix_item(self, unicode key, default=RAISE_KEY_ERROR):
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
                return key, _terminal_state_data(state, tmp_state)

            if default is RAISE_KEY_ERROR:
                raise KeyError(key)
            return default
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

    def items(self, unicode prefix=None):
        """
        Returns a list of this trie's items (``(key,value)`` tuples).

        If ``prefix`` is not None, returns only the items
        associated with keys prefixed by ``prefix``.
        """
        return self._walk_prefixes(prefix, _items_enum_func)

    def keys(self, unicode prefix=None):
        """
        Returns a list of this trie's keys.

        If ``prefix`` is not None, returns only the keys prefixed by ``prefix``.
        """
        return self._walk_prefixes(prefix, _keys_enum_func)

    def values(self, unicode prefix=None):
        """
        Returns a list of this trie's values.

        If ``prefix`` is not None, returns only the values
        associated with keys prefixed by ``prefix``.
        """
        return self._walk_prefixes(prefix, _values_enum_func)

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

    cdef list _walk_prefixes(self, unicode prefix, cdatrie.TrieEnumFunc enum_func):
        """
        Calls ``enum_func`` for each node which key starts with ``prefix``.
        Passes result list to ``enum_func`` as ``user_data`` argument.
        ``enum_func`` is expected to add values to this list.
        """
        cdef:
            cdatrie.TrieState* state = cdatrie.trie_root(self._c_trie)
            cdatrie.TrieState* tmp_state = cdatrie.trie_state_clone(state)

            cdatrie._TrieState* _state = <cdatrie._TrieState *> state
            cdatrie._Trie* trie = <cdatrie._Trie*> self._c_trie

            list result = []
            unicode key
            cdatrie.TrieData value
            cdatrie._TrieEnumData enum_data
            cdatrie.AlphaChar* tail_suffix

        if state == NULL or tmp_state == NULL:
            raise MemoryError()

        try:
            # move the state to the end of the prefix
            if prefix:
                for char in prefix:
                    if not cdatrie.trie_state_walk(state, <cdatrie.AlphaChar> char):
                        return result

            if cdatrie.trie_state_is_single(state):
                # state is in the tail pool
                tail_suffix = cdatrie.alpha_map_trie_to_char_str(
                    _state.trie.alpha_map,
                    cdatrie.tail_get_suffix(_state.trie.tail, _state.index)
                )
                if tail_suffix == NULL:
                    raise MemoryError()

                try:
                    # TODO: more efficient key reconstruction
                    key = prefix + unicode_from_alpha_char(tail_suffix)[_state.suffix_idx:]
                    try:
                        alpha_key = new_alpha_char_from_unicode(key)
                        value = cdatrie.trie_state_get_data(state)
                        enum_func(alpha_key, value, <void *>result)
                    finally:
                        free(alpha_key)
                finally:
                    free(tail_suffix)

                return result

            # state is in double-array structure, enumerate works
            enum_data.trie      = self._c_trie
            enum_data.enum_func = enum_func
            enum_data.user_data = <void*> result

            # This can be optimized: most time is spent in utf_32_le
            # decoding from AlphaChar* inside enum functions; at least
            # prefix may be decoded only once.
            cdatrie.da_enumerate_recursive(
                _state.trie.da,
                _state.index,
                cdatrie.trie_da_enum_func,
                &enum_data
            )

            return result
        finally:
            cdatrie.trie_state_free(state)
            cdatrie.trie_state_free(tmp_state)



cdef class Trie(BaseTrie):
    """
    Wrapper for libdatrie's trie.
    Keys are unicode strings, values are Python objects.
    """

    cdef list _values

    def __init__(self, alphabet=None, ranges=None, AlphaMap alpha_map=None, _create=True):
        """
        For efficiency trie needs to know what unicode symbols
        it should be able to store so this constructor requires
        either ``alphabet`` (a string/iterable with all allowed characters),
        ``ranges`` (a list of (begin, end) pairs, e.g. [('a', 'z')])
        or ``alpha_map`` (:class:`datrie.AlphaMap` instance).
        """

        self._values = []
        super(Trie, self).__init__(alphabet, ranges, alpha_map, _create)

    def __getitem__(self, unicode key):
        cdef cdatrie.TrieData index = self._getitem(key)
        return self._values[index]

    def __setitem__(self, unicode key, object value):
        cdef cdatrie.TrieData next_index = len(self._values)
        cdef cdatrie.TrieData index = self._setdefault(key, next_index)
        if index == next_index:
            self._values.append(value) # insert
        else:
            self._values[index] = value # update

    def setdefault(self, unicode key, object value):
        cdef cdatrie.TrieData next_index = len(self._values)
        cdef cdatrie.TrieData index = self._setdefault(key, next_index)

        if index == next_index:
            self._values.append(value) # insert
            return value
        else:
            return self._values[index] # lookup

    def __delitem__(self, unicode key):
        # XXX: this could be faster (key is encoded twice here)
        cdef cdatrie.TrieData index = self._getitem(key)
        self._values[index] = DELETED_OBJECT
        if not self._delitem(key):
            raise KeyError(key)

    def write(self, f):
        """
        Writes a trie to a file. File-like objects without real
        file descriptors are not supported.
        """
        super(Trie, self).write(f)

        # pickle protocol 2 is used because it is more portable
        pickle.dump(self._values, f, 2)

    @classmethod
    def read(cls, f):
        """
        Creates a new Trie by reading it from file.
        File-like objects without real file descriptors are not supported.
        """
        cdef Trie trie = super(Trie, cls).read(f)
        trie._values = pickle.load(f)
        return trie


    def items(self, unicode prefix=None):
        """
        Returns a list of this trie's items (``(key,value)`` tuples).

        If ``prefix`` is not None, returns only the items
        associated with keys prefixed by ``prefix``.
        """
        return [(key, self._values[value]) for (key, value) in self._walk_prefixes(prefix, _items_enum_func)]

    def values(self, unicode prefix=None):
        """
        Returns a list of this trie's values.

        If ``prefix`` is not None, returns only the values
        associated with keys prefixed by ``prefix``.
        """
        return [self._values[val] for val in self._walk_prefixes(prefix, _values_enum_func)]

    def longest_prefix_item(self, unicode key, default=RAISE_KEY_ERROR):
        """
        Returns the item (``(key,value)`` tuple) associated with the longest
        key in this trie that is a prefix of ``key``.

        If the trie doesn't contain any prefix of ``key``:
          - if ``default`` is given, returns it,
          - otherwise raises ``KeyError``.
        """
        cdef res = self._longest_prefix_item(key, RERAISE_KEY_ERROR)
        if res is RERAISE_KEY_ERROR: # error
            if default is RAISE_KEY_ERROR:
                raise KeyError(key)
            return default

        return res[0], self._values[res[1]]

    def prefix_items(self, unicode key):
        '''
        Returns a list of the items (``(key,value)`` tuples)
        of this trie that are associated with keys that are
        prefixes of ``key``.
        '''
        return [(k, self._values[v]) for (k, v) in self._prefix_items(key)]

    def iter_prefix_items(self, unicode key):
        for k, v in super(Trie, self).iter_prefix_items(key):
            yield k, self._values[v]




cdef bint _items_enum_func(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *user_data):
    """ enum_func for .items() method  """
    (<list> user_data).append(
        (unicode_from_alpha_char(key), <int>key_data)
    )
    return True

cdef bint _keys_enum_func(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *user_data):
    """ enum_func for .keys() method  """
    (<list> user_data).append(unicode_from_alpha_char(key))
    return True

cdef bint _values_enum_func(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *user_data):
    """ enum_func for .values() method  """
    (<list> user_data).append(<int> key_data)
    return True

cdef cdatrie.TrieData _terminal_state_data(cdatrie.TrieState* state, cdatrie.TrieState* tmp_state):
    """ Wrapper for cdatrie.trie_state_get_data that handle non-leaf nodes. """
    if cdatrie.trie_state_is_single(state): # leaf
        return cdatrie.trie_state_get_data(state)
    else: # non-leaf terminal, data is not available here
        cdatrie.trie_state_copy(tmp_state, state)
        cdatrie.trie_state_walk(tmp_state, cdatrie.TRIE_CHAR_TERM)
        return cdatrie.trie_state_get_data(tmp_state)

cdef bint trie_enum_helper(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *py_func):
     cdef unicode py_key = unicode_from_alpha_char(key)
     cdef int py_data = <int>key_data
     res = (<object>py_func)(py_key, py_data)
     return res

cdef bint _trie_counter(cdatrie.AlphaChar *key, cdatrie.TrieData key_data, void *counter):
     """ enum_func for __len__ method """
     (<int *>counter)[0] += 1
     return 1

cdef (cdatrie.Trie* ) _load_from_file(f) except NULL:
    cdef int fd = f.fileno()
    cdef stdio.FILE* f_ptr = stdio_ext.fdopen(fd, "r")
    if f_ptr == NULL:
        raise IOError()
    cdef cdatrie.Trie* trie = cdatrie.trie_fread(f_ptr)
    if trie == NULL:
        raise DatrieError("Can't load trie from stream")

    cdef int f_pos = stdio.ftell(f_ptr)
    f.seek(f_pos)

    return trie

#cdef (cdatrie.Trie*) _load_from_file(path) except NULL:
#    str_path = path.encode(sys.getfilesystemencoding())
#    cdef char* c_path = str_path
#    cdef cdatrie.Trie* trie = cdatrie.trie_new_from_file(c_path)
#    if trie is NULL:
#        raise DatrieError("Can't load trie from file")
#
#    return trie


# ============================ AlphaMap & utils ================================

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

    The caller should free the result of this function.
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

def new(alphabet=None, ranges=None, AlphaMap alpha_map=None):
    warnings.warn('datrie.new is deprecated; please use datrie.Trie.', DeprecationWarning)
    return Trie(alphabet, ranges, alpha_map)


