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

In addition to implementing the mapping interface, tries facilitate
finding the items for a given prefix, and vice versa, finding the
items whose keys are prefixes of a given string. As a common special
case, finding the longest-prefix item is also supported.

.. warning::

    For efficiency you must define allowed character range(s) while
    creating trie. ``datrie`` doesn't check if keys are in allowed
    ranges at runtime, so be careful! Invalid keys are OK at lookup time
    but values won't be stored correctly for such keys.

Add some values to it (datrie keys must be unicode; the example
is for Python 2.x)::

    >>> trie[u'foo'] = 5
    >>> trie[u'foobar'] = 10
    >>> trie[u'bar'] = 20

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

Find all prefixes of a word::

    >>> trie.prefixes(u'foobarbaz')
    [u'foo', u'foobar']

    >>> trie.prefix_items(u'foobarbaz')
    [(u'foo', 5), (u'foobar', 10)]

    >>> trie.iter_prefixes(u'foobarbaz')
    <generator object ...>

    >>> trie.iter_prefix_items(u'foobarbaz')
    <generator object ...>

Find the longest prefix of a word::

    >>> trie.longest_prefix(u'foo')
    u'foo'

    >>> trie.longest_prefix(u'foobarbaz')
    u'foobar'

    >>> trie.longest_prefix(u'gaz')
    KeyError: u'gaz'

    >>> trie.longest_prefix(u'gaz', default=u'vasia')
    u'vasia'

    >>> trie.longest_prefix_item(u'foobarbaz')
    (u'foobar', 10)

Check if the trie has keys with a given prefix::

    >>> trie.has_keys_with_prefix(u'fo')
    True

    >>> trie.has_keys_with_prefix(u'FO')
    False


Performance
===========

Performance is measured against Python's dict with 100k unique unicode
words (English and Russian) as keys and '1' numbers as values.

``datrie.Trie`` uses about 4.6M memory for 100k words; Python's dict
uses about 22M for this according to my unscientific tests.

This trie implementation is 2-6 times slower than python's dict
on __getitem__. Benchmark results (macbook air i5 1.7GHz,
"1.000M ops/sec" == "1 000 000 operations per second")::

    Python 2.6:

    dict __getitem__: 6.024M ops/sec
    trie __getitem__: 2.272M ops/sec

    Python 2.7:
    dict __getitem__: 6.693M ops/sec
    trie __getitem__: 2.357M ops/sec

    Python 3.2:
    dict __getitem__: 3.628M ops/sec
    trie __getitem__: 1.980M ops/sec

Prefix methods are almost as fast as __getitem__ (results are for Python 3.2,
they are even faster under Python 2.x on my machine)::

    trie.iter_prefix_items (hits):      0.738M ops/sec
    trie.prefix_items (hits):           0.883M ops/sec
    trie.prefix_items loop (hits):      0.705M ops/sec
    trie.iter_prefixes (hits):          0.857M ops/sec
    trie.iter_prefixes (misses):        1.628M ops/sec
    trie.iter_prefixes (mixed):         1.412M ops/sec
    trie.has_keys_with_prefix (hits):   1.960M ops/sec
    trie.has_keys_with_prefix (misses): 2.712M ops/sec
    trie.longest_prefix (hits):         1.791M ops/sec
    trie.longest_prefix (misses):       1.616M ops/sec
    trie.longest_prefix (mixed):        1.634M ops/sec

Please take this benchmark results with a grain of salt; this
is a very simple benchmark and may not cover your use case.

Current Limitations
===================

* It requires Cython for installation (this requirement will be removed
  in release);
* keys must be unicode (no implicit conversion for byte strings
  under Python 2.x, sorry);
* values must be integers 0 <= x <= 2147483647;
* **searching for the items for a given prefix is not supported yet**;
* ``.keys()``, ``.values()`` and ``.items()`` trie methods return
  lists, not iterators; they (+ ``len(trie)``) are very slow;
* insertion time is not benchmarked and optimized (but it shouldn't be slow);
* pypy is currently unsupported (because `libdatrie`_ wrapper is
  implemented in Cython and pypy's cpyext doesn't understand the generated
  code);
* the library doesn't compile under Windows + MSVC2008 because of
  missing stdint header.

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

Please note that benchmarks are not included in the release
tar.gz's because benchmark data is large and this
saves a lot of bandwidth; please use source checkouts from
github or bitbucket for the benchmarks.

.. _cython: http://cython.org

Authors & Contributors
----------------------

* Mikhail Korobov <kmike84@gmail.com>

This module is based on `libdatrie`_ C library and
inspired by `fast_trie`_ Ruby bindings; API is inspired by
`PyTrie`_ and `Tree::Trie`_; some docs are borrowed from
these projects.

.. note::

    The implementation is however totally different from
    fast_trie's. ``fast_trie`` bundles libdatrie 0.1.x
    (modified to make it C Ruby extension);
    ``datrie`` bundles libdatrie 0.2.x unmodified (for easier
    upstream updates) and provides a Cython wrapper.

.. _fast_trie: https://github.com/tyler/trie
.. _PyTrie: https://bitbucket.org/gsakkis/pytrie
.. _Tree::Trie: http://search.cpan.org/~avif/Tree-Trie-1.9/Trie.pm

License
=======

Licensed under LGPL v3.