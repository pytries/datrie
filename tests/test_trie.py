# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import datrie
import tempfile
import string
import random

def test_trie():
    trie = datrie.new(alphabet=string.printable)
    assert trie.is_dirty() == True

    assert 'foo' not in trie
    assert 'Foo' not in trie

    trie['foo'] = 5
    assert 'foo' in trie
    assert trie['foo'] == 5

    trie['Foo'] = 10
    assert trie['Foo'] == 10
    assert trie['foo'] == 5
    del trie['foo']

    assert 'foo' not in trie
    assert 'Foo' in trie
    assert trie['Foo'] == 10

    try:
        x = trie['bar']
        assert 0 == 1, "KeyError not raised"
    except KeyError:
        pass

def test_trie_save_load():
    fd, fname = tempfile.mkstemp()
    trie = datrie.new(alphabet=string.printable)
    trie['foobar'] = 1
    trie['foovar'] = 2
    trie['baz'] = 3
    trie['fo'] = 4
    trie['Foo'] = 5
    trie.save(fname)
    del trie

    trie2 = datrie.load(fname)
    assert trie2['foobar'] == 1
    assert trie2['baz'] == 3
    assert trie2['fo'] == 4
    assert trie2['foovar'] == 2
    assert trie2['Foo'] == 5


def test_trie_unicode():
    # trie for lowercase Russian characters
    trie = datrie.new(ranges=[('а', 'я')])
    trie['а'] = 1
    trie['б'] = 2
    trie['аб'] = 3

    assert trie['а'] == 1
    assert trie['б'] == 2
    assert trie['аб'] == 3

def test_trie_ascii():
    trie = datrie.new(string.ascii_letters)
    trie['x'] = 1
    trie['y'] = 3
    trie['xx'] = 2

    assert trie['x'] == 1
    assert trie['y'] == 3
    assert trie['xx'] == 2

def test_trie_items():
    trie = datrie.new(string.ascii_lowercase)
    trie['foo'] = 10
    trie['bar'] = 20
    trie['foobar'] = 30
    assert trie.items() == [('bar', 20), ('foo', 10), ('foobar', 30)]
    assert trie.keys() == ['bar', 'foo', 'foobar']
    assert trie.values() == [20, 10, 30]

def test_trie_keys_prefix():
    trie = datrie.new(string.ascii_lowercase)
    trie['foo'] = 10
    trie['bar'] = 20
    trie['foobar'] = 30
    trie['foovar'] = 40
    trie['foobarzartic'] = 50
    assert trie.keys('foobarz') == ['foobarzartic']
    assert trie.keys('foobarzart') == ['foobarzartic']
    assert trie.keys('foo') == ['foo', 'foobar', 'foobarzartic', 'foovar']
    assert trie.keys('foobar') == ['foobar', 'foobarzartic']
    assert trie.keys('') == ['bar', 'foo', 'foobar', 'foobarzartic', 'foovar']
    assert trie.keys('x') == []

def test_trie_items_prefix():
    trie = datrie.new(string.ascii_lowercase)
    trie['foo'] = 10
    trie['bar'] = 20
    trie['foobar'] = 30
    trie['foovar'] = 40
    trie['foobarzartic'] = 50
    assert trie.items('foobarz') == [('foobarzartic', 50)]
    assert trie.items('foobarzart') == [('foobarzartic', 50)]
    assert trie.items('foo') == [('foo', 10), ('foobar', 30), ('foobarzartic', 50), ('foovar', 40)]
    assert trie.items('foobar') == [('foobar', 30), ('foobarzartic', 50)]
    assert trie.items('') == [('bar', 20), ('foo', 10), ('foobar', 30), ('foobarzartic', 50), ('foovar', 40)]
    assert trie.items('x') == []

def test_trie_values_prefix():
    trie = datrie.new(string.ascii_lowercase)
    trie['foo'] = 10
    trie['bar'] = 20
    trie['foobar'] = 30
    trie['foovar'] = 40
    trie['foobarzartic'] = 50
    assert trie.values('foobarz') == [50]
    assert trie.values('foobarzart') == [50]
    assert trie.values('foo') == [10, 30, 50, 40]
    assert trie.values('foobar') == [30, 50]
    assert trie.values('') == [20, 10, 30, 50, 40]
    assert trie.values('x') == []

def test_trie_len():
    trie = datrie.new(string.ascii_lowercase)
    words = ['foo', 'f', 'faa', 'bar', 'foobar']
    for word in words:
        trie[word] = 1
    assert len(trie) == len(words)

def test_trie_iter_prefixes():
    trie = datrie.new(string.ascii_lowercase)
    words = ['producers', 'producersz', 'pr', 'pool', 'prepare', 'preview', 'prize', 'produce', 'producer', 'progress']
    for index, word in enumerate(words, 1):
        trie[word] = index

    prefixes = trie.iter_prefixes('producers')
    assert list(prefixes) == ['pr', 'produce', 'producer', 'producers']

    no_prefixes = trie.iter_prefixes('vasia')
    assert list(no_prefixes) == []

    items = trie.iter_prefix_items('producers')
    assert next(items) == ('pr', 3)
    assert next(items) == ('produce', 8)
    assert next(items) == ('producer', 9)
    assert next(items) == ('producers', 1)

    no_prefixes = trie.iter_prefix_items('vasia')
    assert list(no_prefixes) == []


def test_trie_prefixes():
    trie = datrie.new(string.ascii_lowercase)
    words = ['producers', 'producersz', 'pr', 'pool', 'prepare', 'preview', 'prize', 'produce', 'producer', 'progress']
    for index, word in enumerate(words, 1):
        trie[word] = index

    prefixes = trie.prefixes('producers')
    assert prefixes == ['pr', 'produce', 'producer', 'producers']


    items = trie.prefix_items('producers')
    assert items == [('pr', 3), ('produce', 8), ('producer', 9), ('producers', 1)]

    assert trie.prefixes('vasia') == []
    assert trie.prefix_items('vasia') == []


def test_has_keys_with_prefix():
    trie = datrie.new(string.ascii_lowercase)
    words = ['pool', 'prepare', 'preview', 'prize', 'produce', 'producer', 'progress']
    for word in words:
        trie[word] = 1

    for word in words:
        assert trie.has_keys_with_prefix(word)
        assert trie.has_keys_with_prefix(word[:-1])

    assert trie.has_keys_with_prefix('p')
    assert trie.has_keys_with_prefix('poo')
    assert trie.has_keys_with_prefix('pr')
    assert trie.has_keys_with_prefix('priz')

    assert not trie.has_keys_with_prefix('prizey')
    assert not trie.has_keys_with_prefix('ops')
    assert not trie.has_keys_with_prefix('progn')


def test_longest_prefix():
    trie = datrie.new(string.ascii_lowercase)
    words = ['pool', 'prepare', 'preview', 'prize', 'produce', 'producer', 'progress']
    for word in words:
        trie[word] = 1

    for word in words:
        assert trie.longest_prefix(word) == word
    assert trie.longest_prefix('pooler') == 'pool'
    assert trie.longest_prefix('producers') == 'producer'
    assert trie.longest_prefix('progressor') == 'progress'

    assert trie.longest_prefix('prview', default=None) == None
    assert trie.longest_prefix('p', default=None) == None
    assert trie.longest_prefix('z', default=None) == None

    try:
        trie.longest_prefix('z')
        assert False
    except KeyError:
        pass



def test_trie_fuzzy():
    russian = 'абвгдеёжзиклмнопрстуфхцчъыьэюя'
    alphabet = russian.upper() + string.ascii_lowercase
    words = list(set([
        "".join([random.choice(alphabet) for x in range(random.randint(2,10))])
        for y in range(1000)
    ]))

    trie = datrie.new(alphabet)

    enumerated_words = list(enumerate(words))

    for index, word in enumerated_words:
        trie[word] = index

    random.shuffle(enumerated_words)
    for index, word in enumerated_words:
        assert word in trie, word
        assert trie[word] == index, (word, index)


#def test_large_trie():
#    zf = zipfile.ZipFile('words100k.txt.zip')
#    words = zf.open(zf.namelist()[0]).read().decode('utf8').splitlines()

