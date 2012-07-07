# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals

import _datrie

import string

def test_alphamap():
    # we can't check anything; make sure it at least doesn't crash
    alpha_map = _datrie.AlphaMap()
    alpha_map.add_range('a', 'z')
    del alpha_map

