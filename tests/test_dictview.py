# -*- coding: utf-8 -*-

from __future__ import absolute_import, unicode_literals

import string
import datrie


def test_keys_empty():
    trie = datrie.BaseTrie(string.printable)
    keys = trie.keys()
    assert len(keys) == 0


def test_keys_iter():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys_list = list(trie.keys())
    keys_list.sort()
    assert keys_list == ["1", "2"]


def test_keys_iter_with_prefix():
    trie = datrie.BaseTrie(string.printable)
    trie["prefix1_1"] = 11
    trie["prefix1_2"] = 12
    trie["prefix2_1"] = 21
    trie["prefix2_2"] = 22
    keys = trie.keys(prefix="prefix1")
    keys_list = list(keys)
    keys_list.sort()
    assert keys_list == ["prefix1_1", "prefix1_2"]


def test_keys_contains():
    trie = datrie.BaseTrie(string.printable)
    trie["prefix1_1"] = 11
    trie["prefix1_2"] = 12
    trie["prefix2_1"] = 21
    trie["prefix2_2"] = 22
    keys = trie.keys()
    assert "prefix1_1" in keys
    assert "prefix2_1" in keys
    keys = trie.keys(prefix="prefix1")
    assert "prefix1_1" in keys
    assert "prefix2_1" not in keys


def test_keys_len():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    keys = trie.keys()
    assert len(trie) == 1
    assert len(keys) == 1
    trie["1"] = 2
    trie["2"] = 2
    assert len(keys) == 2
    trie["prefix_3"] = 3
    keys = trie.keys(prefix="prefix")
    assert len(keys) == 1


def test_keys_prefix():
    trie = datrie.BaseTrie(string.printable)
    trie["prefix1_1"] = 11
    trie["prefix1_2"] = 12
    trie["prefix2_3"] = 21
    keys = trie.keys(prefix="prefix")
    assert len(keys) == 3
    keys = trie.keys(prefix="prefix1_")
    assert len(keys) == 2
    keys_list = list(keys)
    keys_list.sort()
    assert keys_list == ["prefix1_1", "prefix1_2"]


def test_keys_delete():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    del trie["1"]
    assert len(trie) == 1
    assert len(keys) == 1
