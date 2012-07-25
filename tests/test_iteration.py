# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import string
import datrie

def test_data():
    trie = datrie.BaseTrie(string.printable)
    trie['x'] = 1
    trie['xo'] = 2
    state = datrie.TrieState(trie)
    state.walk('x')

    it = datrie.TrieIterator(state)
    assert it.data() == 1

    state.walk('o')

    it = datrie.TrieIterator(state)
    assert it.data() == 2.
