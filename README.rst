datrie
======

Super-fast, efficiently stored Trie for Python (2.x and 3.x).
Uses `libdatrie`_.

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

Performance
===========

Performance is measured against Python's dict with 100k unique words
(English and Russian) as keys and '1' numbers as values.

This trie implementation is 2-3 times slower than python's dict
on __getitem__. Benchmark results (macbook air i5 1.7GHz)::

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

Current Limitations
===================

* It requires Cython for installation (this requirement will be removed
  in release);
* most useful trie methods (e.g. prefix search) are not yet implemented;
* pypy is currently unsupported (because `libdatrie`_ wrapper is
  implemented in Cython and pypy's cpyext doesn't understand the generated
  code);
* keys must be unicode (no implicit conversion for byte strings
  under Python 2.x, sorry);
* values must be integers;
* ``keys()``, ``values()`` and ``items()`` trie methods return
  lists, not iterators;
* the library is not tested under Windows.

Contributing
============

Development happens at github and bitbucket:

* https://github.com/kmike/datrie
* https://bitbucket.org/kmike/datrie

The main issue tracker is at github.

Feel free to submit ideas, bugs, pull requests (git or hg) or
regular patches.

Running tests and benchmarks
----------------------------

Make sure `cython`_ and `tox <http://tox.testrun.org>`_ are installed and run

::

    $ tox

from the source checkout. Tests should pass under python 2.6, 2.7
and 3.2.

::

    $ tox -c tox-bench.ini

runs benchmarks.

Please note that tests and benchmarks are not included
in the release tar.gz's (test/benchmark data is large and this
saves a lot of bandwidth); please use source checkouts from
github or bitbucket.

.. _cython: http://cython.org

Authors & Contributors
----------------------

* Mikhail Korobov <kmike84@gmail.com>

This module is based on `libdatrie`_ C library and
inspired by `fast_trie`_ Ruby bindings.

.. note::

    The implementation is however totally different from
    fast_trie's. ``fast_trie`` bundles libdatrie 0.1.x
    (modified to make it C Ruby extension);
    ``datrie`` bundles libdatrie 0.2.x unmodified (for easier
    upstream updates) and provides a Cython wrapper.

.. _fast_trie: https://github.com/tyler/trie

License
=======

Licensed under LGPL v3.