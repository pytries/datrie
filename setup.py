#! /usr/bin/env python
"""Super-fast, efficiently stored Trie for Python."""

import os

from setuptools import setup, Extension

LIBDATRIE_DIR = 'libdatrie/datrie'
LIBDATRIE_FILE_NAMES = [
    'alpha-map.c', 'darray.c', 'fileutils.c', 'tail.c', 'trie.c',
    'dstring.c', 'trie-string.c',
]
LIBDATRIE_FILES = [os.path.join(LIBDATRIE_DIR, name)
                   for name in LIBDATRIE_FILE_NAMES]

DESCRIPTION = __doc__
LONG_DESCRIPTION = open('README.rst').read() + open('CHANGES.rst').read()
LICENSE = 'LGPLv2+'

CLASSIFIERS = [
    'Development Status :: 4 - Beta',
    'Intended Audience :: Developers',
    'Intended Audience :: Science/Research',
    'License :: OSI Approved :: GNU Lesser General Public License v2 or later (LGPLv2+)',
    'Programming Language :: Cython',
    'Programming Language :: Python',
    'Programming Language :: Python :: 2',
    'Programming Language :: Python :: 2.6',
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.3',
    'Programming Language :: Python :: 3.4',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: Implementation :: CPython',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: Scientific/Engineering :: Information Analysis',
    'Topic :: Text Processing :: Linguistic'
]


setup(
    name="datrie",
    version="0.7",
    description=DESCRIPTION,
    long_description=LONG_DESCRIPTION,
    author='Mikhail Korobov',
    author_email='kmike84@gmail.com',
    license=LICENSE,
    url='https://github.com/kmike/datrie',
    classifiers=CLASSIFIERS,
    libraries=[
        ('libdatrie', dict(
            sources=LIBDATRIE_FILES,
            include_dirs=["libdatrie"],
        ))
    ],
    ext_modules=[
        Extension("datrie", [
            'src/datrie.c',
            'src/cdatrie.c',
            'src/stdio_ext.c'
        ], include_dirs=['libdatrie'])
    ],

    setup_requires=["pytest-runner"],
    tests_require=["pytest", "hypothesis"],
)
