# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals
import datrie

def test_alphamap():
    # we can't check anything; make sure it at least doesn't crash
    alpha_map = datrie.AlphaMap()
    alpha_map.add_range('a', 'z')
    del alpha_map
