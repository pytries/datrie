datrie
======

Super-fast, efficiently stored Trie for Python. Uses `libdatrie`_.

.. _libdatrie: http://linux.thai.net/~thep/datrie/datrie.html

Installation
============

::

    pip install datrie

Usage
=====

Create a new trie capable of storing lower-case ascii letters::

    >>> import string
    >>> import datrie
    >>> trie = datrie.new(string.ascii_lowercase)

``trie`` variable is a dict-like object that can have unicode keys of
certain ranges and integer values.

.. warning::

    For efficiency you must define allowed character range(s) while
    creating trie. ``datrie`` doesn't check if keys are in allowed
    ranges at runtime, so be careful! Invalid keys are OK at lookup time
    but values won't be stored correctly for such keys.

Add some values to it (datrie keys must be unicode; the example
is for Python 2.x)::

    >>> trie[u'foo'] = 5
    >>> trie[u'foobar'] = 10

Check if u'foo' is in trie::

    >>> u'foo' in trie
    True

Get a value::

    >>> trie[u'foo']
    5

Save a trie to disk::

    >>> trie.save('my.trie')

Load a trie::

    >>> trie2 = datrie.load('my.trie')


TODO: implement useful trie methods.

Performance
===========

Performance is measured against Python's dict with 100k unique words
(English and Russian) as keys and '1' numbers as values.

This trie implementation is 2-3 times slower than python's dict
on __getitem__. Benchmark results (macbook air i5 1.7GHz):

    Python 2.6:

    dict __getitem__: 6024K words/sec
    trie __getitem__: 2272K words/sec

    Python 2.7:
    dict __getitem__: 6693K words/sec
    trie __getitem__: 2357K words/sec

    Python 3.2:
    dict __getitem__: 3628K words/sec
    trie __getitem__: 1980K words/sec

``datrie.Trie`` uses about 4.6M memory for 100k words; Python's dict
uses about 22M for this according to my unscientific tests.

Contributing
============

Development happens at github and bitbucket:

* https://github.com/kmike/datrie
* https://bitbucket.org/kmike/datrie

The main issue tracker is at github.

Feel free to submit ideas, bugs, pull requests (git or hg) or regular patches.

Running tests
-------------

Make sure `tox <http://tox.testrun.org>`_ is installed and run

::

    $ tox

from the source checkout. Tests should pass under python 2.6..3.2
and pypy > 1.8.

Authors & Contributors
----------------------

- Mikhail Korobov <kmike84@gmail.com>

License
=======

Licensed under LGPL v3.