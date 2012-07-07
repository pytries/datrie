#! /usr/bin/env python
import os
from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

LIBDATRIE_DIR = 'libdatrie/datrie'
LIBDATRIE_FILE_NAMES = [
    'alpha-map.c', 'darray.c', 'fileutils.c', 'tail.c', 'trie.c',
]
LIBDATRIE_FILES = [os.path.join(LIBDATRIE_DIR, name) for name in LIBDATRIE_FILE_NAMES]

setup(
    name="datrie",
    version="0.1",
    description="A Python wrapper for libdatrie",
    long_description = open('README.rst').read(),
    author='Mikhail Korobov',
    author_email='kmike84@gmail.com',
    packages = ['datrie'],
    cmdclass = {'build_ext': build_ext},

    ext_modules = [
        Extension(
            "_datrie",
            ['ext/_datrie.pyx', 'ext/cdatrie.pxd'] + LIBDATRIE_FILES,
            include_dirs=['libdatrie'],
        )
    ]
)



