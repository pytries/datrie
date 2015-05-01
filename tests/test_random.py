# -*- coding: utf-8 -*-

from __future__ import absolute_import, unicode_literals

import pickle
import string

import datrie
from hypothesis import given
from hypothesis.specifiers import strings


printable_strings = [strings(string.printable)]


@given(printable_strings)
def test_contains(words):
    trie = datrie.Trie(string.printable)
    for i, word in enumerate(set(words)):
        trie[word] = i

    for i, word in enumerate(set(words)):
        assert word in trie
        assert trie[word] == i


@given(printable_strings)
def test_len(words):
    trie = datrie.Trie(string.printable)
    for i, word in enumerate(set(words)):
        trie[word] = i

    assert len(trie) == len(set(words))


@given(printable_strings)
def test_pickle_unpickle(words):
    trie = datrie.Trie(string.printable)
    for i, word in enumerate(set(words)):
        trie[word] = i

    trie = pickle.loads(pickle.dumps(trie))
    for i, word in enumerate(set(words)):
        assert word in trie
        assert trie[word] == i
