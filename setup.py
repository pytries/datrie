#! /usr/bin/env python
import os
from distutils.core import setup
from distutils.extension import Extension
#from Cython.Distutils import build_ext

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
    url='https://github.com/kmike/datrie/',
    #packages = ['datrie'],
    #cmdclass = {'build_ext': build_ext},

    ext_modules = [
        Extension(
            "datrie",
            ['src/datrie.c', 'src/cdatrie.c'] + LIBDATRIE_FILES,
            include_dirs=['libdatrie'],
        )
    ],

    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Intended Audience :: Science/Research',
        'License :: OSI Approved :: GNU Lesser General Public License v3 (LGPLv3)',
        'Programming Language :: Cython',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.2',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Scientific/Engineering :: Information Analysis',
        'Topic :: Text Processing :: Linguistic',
    ],

)



