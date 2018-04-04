# -*- coding: utf-8 -*-

from __future__ import absolute_import, unicode_literals

import pytest
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
    keys = trie.keys()
    keys_list = list(keys)
    keys_list.sort()
    assert keys_list == ["1", "2"]
    del trie["2"]
    assert list(keys) == ["1"]


def test_keys_iter_with_prefix():
    trie = datrie.BaseTrie(string.printable)
    keys = trie.keys(prefix="prefix1")
    keys_list = list(keys)
    assert keys_list == []
    trie["prefix1_1"] = 11
    trie["prefix1_2"] = 12
    trie["prefix2_1"] = 21
    trie["prefix2_2"] = 22
    keys_list = list(keys)
    keys_list.sort()
    assert keys_list == ["prefix1_1", "prefix1_2"]
    del trie["prefix1_1"]
    del trie["prefix1_2"]
    assert list(keys) == []


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
    trie["1"] = 1
    keys = trie.keys()
    assert "1" in keys
    assert 1 not in keys
    assert [1] not in keys
    items = trie.items()
    assert ("1", 1) in items
    assert (1, 1) not in items


def test_keys_len():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    keys = trie.keys()
    assert len(trie) == 1
    assert len(keys) == 1
    trie["1"] = 2
    trie["2"] = 2
    trie["prefix_3"] = 3
    assert len(keys) == 3
    keys = trie.keys(prefix="prefix")
    assert len(keys) == 1
    del trie["1"]
    del trie["2"]
    assert len(keys) == 1
    del trie["prefix_3"]
    assert len(keys) == 0


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
    del trie["prefix1_1"]
    del trie["prefix2_3"]
    assert list(keys) == ["prefix1_2"]


def test_keys_delete():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    del trie["1"]
    assert len(trie) == 1
    assert len(keys) == 1


def test_keys_eq():
    """Test trie.keys() == and != operations"""
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert keys == {"1", "2"}
    assert keys == {"2", "1"}
    trie["3"] = 3
    assert keys != {"2", "1"}
    del trie["1"]
    assert keys == {"2", "3"}
    trie["prefix_4"] = 4
    keys = trie.keys(prefix="prefix")
    assert keys == {"prefix_4"}
    assert not keys != {"prefix_4"}
    assert keys != {"1", "2", "3"}


def test_keys_issuperset():
    """Test trie.keys() >= and > operations"""
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert keys >= {"1"}
    with pytest.raises(TypeError):
        _ = keys >= 1  # not iterable
    assert keys >= {"2"}
    assert keys >= {"1", "2"}
    assert not keys >= {"1", "2", "3"}
    assert not keys >= {"3"}
    # Proper superset
    assert keys > {"2"}
    assert not keys > {"1", "2"}
    assert not keys > {"3"}
    # Wrong type inside set
    assert not keys >= {1, 2}
    trie["prefix_3"] = 3
    keys = trie.keys(prefix="prefix")
    assert keys >= {"prefix_3"}
    assert not keys >= {"prefix_3", "1"}
    del trie["prefix_3"]
    assert keys >= set()


def test_keys_issubset():
    """Test trie.keys() <= and < operations"""
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert not keys <= {"1"}
    with pytest.raises(TypeError):
        assert not keys <= 1  # not iterable
        assert keys <= ["1", "2"]  # wrong type
    assert keys <= {"1", "2"}
    assert keys <= {"1", "2", "3"}
    trie["prefix_3"] = 3
    # Proper subset
    assert not keys < {"1", "2"}
    assert not keys < {"1", "2", "prefix_3"}
    assert keys < {"1", "2", "prefix_3", "3"}
    keys = trie.keys(prefix="prefix")
    assert keys <= {"prefix_3"}
    assert keys <= {"prefix_3", "1"}
    assert not keys <= {"1", "2"}
    del trie["prefix_3"]
    assert keys <= {"prefix_3"}
    assert keys <= set()
    assert keys < {"1", "2", "3"}


def test_keys_intersection():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert (keys & keys) == {"1", "2"}
    assert (keys & keys) != set()
    assert (keys & keys) != {"1"}
    assert (keys & keys) != {"2"}
    assert (keys & '1') == {"1"}
    with pytest.raises(TypeError):
        assert (keys & 1) == {"1"}  # not iterable
    assert (keys & 'ab') == set()
    assert (keys & "12") == {"1", "2"}
    assert (keys & "1") == {"1"}
    trie["prefix_3"] = 3
    keys = trie.keys(prefix="prefix_")
    assert (keys & keys) == {"prefix_3"}
    assert (keys & keys) == keys
    assert (keys & "12") == set()
    assert (keys & "") == set()


def test_keys_union():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    trie["333"] = 2
    keys = trie.keys()
    assert (keys | keys) == keys
    assert (keys | set()) == set(keys)
    del trie["333"]
    assert (keys | {"1"}) == {"1", "2"}
    del trie["1"]
    assert (keys | {"1"}) == {"1", "2"}
    assert (keys | {"2"}) == {"2"}
    assert (keys | {"3"}) == {"2", "3"}
    keys = trie.keys(prefix="")
    assert (keys | {"3"}) == {"2", "3"}
    keys = trie.keys(prefix="prefix")
    assert (keys | {"3"}) == {"3"}
    trie["prefix_3"] = 3
    assert (keys | {"3"}) == {"3", "prefix_3"}


def test_keys_difference():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    trie["3"] = 2
    keys = trie.keys()
    assert (keys - set()) == set(keys)
    assert (keys - {"3"}) == {"1", "2"}
    assert (keys - {"2", "3"}) == {"1"}
    assert (keys - {"1", "2", "3"}) == set()
    assert (keys - {"1", "2", "3", "4"}) == set()
    assert (keys - {"4"}) == {"1", "2", "3"}
    keys = trie.keys(prefix="prefix")
    assert (keys - set()) == set()
    assert (keys - {"1"}) == set()
    trie["prefix_1"] = 3
    assert (keys - set()) == {"prefix_1"}
    assert (keys - {"prefix_1"}) == set()
    assert (keys - {"prefix_2"}) == {"prefix_1"}


def test_keys_symmetric_difference():
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert (keys ^ set()) == {"1", "2"}
    assert (keys ^ {"1"}) == {"2"}
    assert (keys ^ {"1", "2"}) == set()
    assert (keys ^ {"1", "2", "3"}) == {"3"}
    del trie["1"]
    assert (keys ^ {"1"}) == {"1", "2"}
    keys = trie.keys(prefix="prefix")
    assert (keys ^ {"1"}) == {"1"}
    trie["prefix_1"] = 3
    assert (keys ^ {"1"}) == {"prefix_1", "1"}


def test_keys_isdisjoint():
    # Return True if null intersection
    trie = datrie.BaseTrie(string.printable)
    trie["1"] = 1
    trie["2"] = 2
    keys = trie.keys()
    assert keys.isdisjoint(set())
    assert not keys.isdisjoint({"1"})
    assert keys.isdisjoint({"3"})
    del trie["1"]
    assert keys.isdisjoint({"1"})
    keys = trie.keys(prefix="prefix")
    assert keys.isdisjoint({"1"})
    assert keys.isdisjoint({"2"})
    trie["prefix_1"] = 3
    assert keys.isdisjoint({"2"})
    assert not keys.isdisjoint({"prefix_1"})
    assert keys.isdisjoint({"prefix_2"})
