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

Add some values to it (datrie keys must be unicode; the examples
are for Python 2.x)::

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

Get all items with a given prefix from a trie::

    >>> trie.keys(u'fo')
    [u'foo', u'foobar']

    >>> trie.items(u'ba')
    [(u'bar', 20)]

    >>> trie.values(u'foob')
    [10]


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

Looking for prefixes of a given word is almost as fast as
__getitem__ (results are for Python 3.2, they are even faster under
Python 2.x on my machine)::

    trie.iter_prefix_items (hits):      0.697M ops/sec
    trie.prefix_items (hits):           0.856M ops/sec
    trie.prefix_items loop (hits):      0.708M ops/sec
    trie.iter_prefixes (hits):          0.854M ops/sec
    trie.iter_prefixes (misses):        1.585M ops/sec
    trie.iter_prefixes (mixed):         1.463M ops/sec
    trie.has_keys_with_prefix (hits):   1.896M ops/sec
    trie.has_keys_with_prefix (misses): 2.623M ops/sec
    trie.longest_prefix (hits):         1.788M ops/sec
    trie.longest_prefix (misses):       1.552M ops/sec
    trie.longest_prefix (mixed):        1.642M ops/sec

Looking for all words starting with a given prefix is mostly limited
by overall result count (this can be improved in future because a
lot of time is spent decoding strings from utf_32_le to Python's
unicode)::

    trie.items(prefix="xxx"), avg_len(res)==415:        0.699K ops/sec
    trie.keys(prefix="xxx"), avg_len(res)==415:         0.708K ops/sec
    trie.values(prefix="xxx"), avg_len(res)==415:       2.165K ops/sec
    trie.items(prefix="xxxxx"), avg_len(res)==17:       16.227K ops/sec
    trie.keys(prefix="xxxxx"), avg_len(res)==17:        16.434K ops/sec
    trie.values(prefix="xxxxx"), avg_len(res)==17:      45.806K ops/sec
    trie.items(prefix="xxxxxxxx"), avg_len(res)==3:     74.912K ops/sec
    trie.keys(prefix="xxxxxxxx"), avg_len(res)==3:      73.857K ops/sec
    trie.values(prefix="xxxxxxxx"), avg_len(res)==3:    170.833K ops/sec
    trie.items(prefix="xxxxx..xx"), avg_len(res)==1.4:  124.003K ops/sec
    trie.keys(prefix="xxxxx..xx"), avg_len(res)==1.4:   124.709K ops/sec
    trie.values(prefix="xxxxx..xx"), avg_len(res)==1.4: 210.586K ops/sec
    trie.items(prefix="xxx"), NON_EXISTING:             1779.258K ops/sec
    trie.keys(prefix="xxx"), NON_EXISTING:              1827.053K ops/sec
    trie.values(prefix="xxx"), NON_EXISTING:            1793.204K ops/sec

Please take this benchmark results with a grain of salt; this
is a very simple benchmark and may not cover your use case.

Current Limitations
===================

* keys must be unicode (no implicit conversion for byte strings
  under Python 2.x, sorry);
* values must be integers 0 <= x <= 2147483647;
* insertion time is not benchmarked and optimized (but it shouldn't be slow);
* it doesn't work under pypy+MacOS X (some obscure error);
* the library doesn't compile under Windows + MSVC2008 because of
  missing ``<stdint.h>`` header.

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

Make sure `tox`_ is installed and run

::

    $ tox

from the source checkout. Tests should pass under python 2.6, 2.7
and 3.2.

::

    $ tox -c tox-bench.ini

runs benchmarks.

If you've changed anything in the source code then
make sure `cython`_ is installed and run

::

    $ update_c.sh

before each ``tox`` command.

Please note that benchmarks are not included in the release
tar.gz's because benchmark data is large and this
saves a lot of bandwidth; use source checkouts from
github or bitbucket for the benchmarks.

.. _cython: http://cython.org
.. _tox: http://tox.testrun.org

Authors & Contributors
----------------------

* Mikhail Korobov <kmike84@gmail.com>

This module is based on `libdatrie`_ C library and is inspired by
`fast_trie`_ Ruby bindings, `PyTrie`_ pure Python implementation
and `Tree::Trie`_ Perl implementation; some docs are borrowed from
these projects.

.. _fast_trie: https://github.com/tyler/trie
.. _PyTrie: https://bitbucket.org/gsakkis/pytrie
.. _Tree::Trie: http://search.cpan.org/~avif/Tree-Trie-1.9/Trie.pm

License
=======

Licensed under LGPL v3.