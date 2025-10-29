#! /usr/bin/env python
"""Super-fast, efficiently stored Trie for Python."""

import glob
import os

from setuptools import setup

from Cython.Build import cythonize

LIBDATRIE_DIR = 'libdatrie'
LIBDATRIE_FILES = sorted(glob.glob(os.path.join(LIBDATRIE_DIR, "datrie", "*.c")))

DESCRIPTION = __doc__
LONG_DESCRIPTION = open('README.rst').read() + open('CHANGES.rst').read()

CLASSIFIERS = [
    'Development Status :: 4 - Beta',
    'Intended Audience :: Developers',
    'Intended Audience :: Science/Research',
    'Programming Language :: Cython',
    'Programming Language :: Python',
    'Programming Language :: Python :: 3.9',
    'Programming Language :: Python :: 3.10',
    'Programming Language :: Python :: 3.11',
    'Programming Language :: Python :: 3.12',
    'Programming Language :: Python :: 3.13',
    'Programming Language :: Python :: Implementation :: CPython',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: Scientific/Engineering :: Information Analysis',
    'Topic :: Text Processing :: Linguistic'
]

ext_modules = cythonize(
    'src/datrie.pyx', 'src/cdatrie.pxd', 'src/stdio_ext.pxd',
    annotate=True,
    include_path=[os.path.join(os.path.dirname(os.path.abspath(__file__)), "src")],
    language_level=2
    )

for m in ext_modules:
    m.include_dirs=[LIBDATRIE_DIR]

setup(name="datrie",
      version="0.8.3",
      description=DESCRIPTION,
      long_description=LONG_DESCRIPTION,
      long_description_content_type="text/x-rst",
      author='Mikhail Korobov',
      author_email='kmike84@gmail.com',
      license="LGPL-2.0-or-later",
      url='https://github.com/kmike/datrie',
      classifiers=CLASSIFIERS,
      libraries=[('datrie', {
          "sources": LIBDATRIE_FILES,
          "include_dirs": [LIBDATRIE_DIR]})],
      ext_modules=ext_modules,
      python_requires=">=3.9",
      setup_requires=['Cython>=0.28'],
      tests_require=["pytest", "hypothesis"])
