# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import _datrie
import tempfile
import string
import zipfile
import random

def _get_trie():
    alpha_map = _datrie.AlphaMap()
    #alpha_map.add_chars(string.printable)
    alpha_map._add_range(20, 5000)
    return _datrie.Trie.create(alpha_map)


def test_trie():
    trie = _get_trie()
    assert trie.is_dirty() == True

    assert 'foo' not in trie
    assert 'Foo' not in trie

    trie['foo'] = 5
    assert 'foo' in trie
    assert trie['foo'] == 5

    trie['Foo'] = 10
    assert trie['Foo'] == 10
    assert trie['foo'] == 5

    try:
        x = trie['bar']
        assert 0 == 1, "KeyError not raised"
    except KeyError:
        pass

def test_trie_save_load():
    fd, fname = tempfile.mkstemp()
    trie = _get_trie()
    trie['foobar'] = 1
    trie['foovar'] = 2
    trie['baz'] = 3
    trie['fo'] = 4
    trie['Foo'] = 5
    trie.save(fname)
    del trie

    trie2 = _datrie.Trie.load(fname)
    assert trie2['foobar'] == 1
    assert trie2['baz'] == 3
    assert trie2['fo'] == 4
    assert trie2['foovar'] == 2
    assert trie2['Foo'] == 5


def test_trie_unicode():
#    alpha_map = _datrie.AlphaMap()
#    alpha_map.add_range('а', 'в')
#    trie = _datrie.Trie.create(alpha_map)
    trie = _get_trie()
    trie['а'] = 1
    trie['б'] = 2
    trie['аб'] = 3

    assert trie['а'] == 1
    assert trie['б'] == 2
    assert trie['аб'] == 3

def test_trie_ascii():
    trie = _get_trie()
    trie['x'] = 1
    trie['y'] = 3
    trie['xx'] = 2

    assert trie['x'] == 1
    assert trie['y'] == 3
    assert trie['xx'] == 2



def test_trie_fuzzy():
    russian = 'абвгдеёжзиклмнопрстуфхцчъыьэюя'
    alphabet = russian #.upper() # + string.ascii_lowercase
    words = list(set([
        "".join([random.choice(alphabet) for x in range(random.randint(2,10))])
        for y in range(1000)
    ]))

    alpha_map = _datrie.AlphaMap()
    alpha_map.add_range('а', 'я')
    #alpha_map.add_range('ё', 'ё')
    #alpha_map.add_chars(alphabet)
    trie = _datrie.Trie.create(alpha_map)

    for index, word in enumerate(words):
        trie[word] = index

    for index, word in enumerate(words):
        assert trie[word] == index

#def test_large_trie():
#    zf = zipfile.ZipFile('words100k.txt.zip')
#    words = zf.open(zf.namelist()[0]).read().decode('utf8').splitlines()

