# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import string
import datrie

WORDS = ['producers', 'pool', 'prepare', 'preview', 'prize', 'produce', 'producer', 'progress']

def _trie():
    trie = datrie.BaseTrie(ranges=[(chr(0), chr(127))])
    for index, word in enumerate(WORDS, 1):
        trie[word] = index

    return trie


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
    assert it.data() == 2

def test_next():
    trie = _trie()
    state = datrie.TrieState(trie)
    it = datrie.TrieIterator(state)

    values = []
    while it.next():
        values.append(it.data())

    assert len(values) == 8
    assert values == [2, 3, 4, 5, 6, 7, 1, 8]


def test_next_non_root():
    trie = _trie()
    state = datrie.TrieState(trie)
    state.walk('pr')
    it = datrie.TrieIterator(state)

    values = []
    while it.next():
        values.append(it.data())

    assert len(values) == 7
    assert values == [3, 4, 5, 6, 7, 1, 8]

def test_next_tail():
    trie = _trie()
    state = datrie.TrieState(trie)
    state.walk('poo')
    it = datrie.TrieIterator(state)

    values = []
    while it.next():
        values.append(it.data())

    assert values == [2]



def test_keys():
    trie = _trie()
    state = datrie.TrieState(trie)
    it = datrie.TrieIterator(state)

    keys = []
    while it.next():
        keys.append(it.key())

    assert keys == sorted(WORDS)


def test_keys_non_root():
    trie = _trie()
    state = datrie.TrieState(trie)
    state.walk('pro')
    it = datrie.TrieIterator(state)

    keys = []
    while it.next():
        keys.append(it.key())

    assert keys == ['duce', 'ducer', 'ducers', 'gress']

def test_keys_tail():
    trie = _trie()
    state = datrie.TrieState(trie)
    state.walk('pro')
    it = datrie.TrieIterator(state)

    keys = []
    while it.next():
        keys.append(it.key())

    assert keys == ['duce', 'ducer', 'ducers', 'gress']
