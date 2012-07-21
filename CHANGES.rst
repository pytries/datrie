
CHANGES
=======

0.3 (2012-07-21)
----------------

There are no new features or speed improvements in this release.

* ``datrie.new`` is deprecated; use ``datrie.Trie`` with the same arguments;
* small test & benchmark improvements.

0.2 (2012-07-16)
----------------

* ``datrie.Trie`` items can have any Python object as a value
  (``Trie`` from 0.1.x becomes ``datrie.BaseTrie``);
* ``longest_prefix`` and ``longest_prefix_items`` are fixed;
* ``save`` & ``load`` are rewritten;
* ``setdefault`` method.


0.1.1 (2012-07-13)
------------------

* Windows support (upstream libdatrie changes are merged);
* license is changed from LGPL v3 to LGPL v2.1 to match the libdatrie license.

0.1 (2012-07-12)
----------------

Initial release.
