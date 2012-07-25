# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import string

import pytest
import datrie

def _trie():
    trie = datrie.BaseTrie(ranges=[(chr(0), chr(127))])
    trie['f'] = 1
    trie['fo'] = 2
    trie['fa'] = 3
    trie['faur'] = 4
    trie['fauxi'] = 5
    trie['fauzox'] = 10
    trie['fauzoy'] = 20
    trie['x'] = 30
    return trie

def test_trie_state():
    trie = _trie()
    state = datrie.TrieState(trie)
    state.walk('f')
    assert state.data() == 1
    state.walk('o')
    assert state.data() == 2

def test_state_next():
    trie = _trie()
    state = datrie.TrieState(trie)
    print('========= state: ', state)
    while state.next():
        print('========== state: ', state)

def test_state_next_values():
    trie = _trie()
    state = datrie.TrieState(trie)

    res = []
    while state.next():
        if state.is_terminal():
            res.append(state.data())

    assert res == [1, 3, 4, 5, 10, 20, 2, 30]

def test_state_next_keys():
    trie = _trie()
    state = datrie.TrieState(trie)

    res = []
    while state.next():
        if state.is_terminal():
            res.append(state.key())

    assert res == ['f', 'fa', 'faur', 'fauxi', 'fauzox', 'fauzoy', 'fo', 'x']

