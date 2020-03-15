#! /usr/bin/env python
"""Super-fast, efficiently stored Trie for Python."""

import glob
import os

from setuptools import setup, Extension

__version__ = '0.8.1'

# make setuptools happy with PEP 440-compliant post version
# (enable this for patch releases)
# REL_TAG = __version__.replace('-', 'p')

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
    'Programming Language :: Python :: 2.7',
    'Programming Language :: Python :: 3',
    'Programming Language :: Python :: 3.5',
    'Programming Language :: Python :: 3.6',
    'Programming Language :: Python :: 3.7',
    'Programming Language :: Python :: Implementation :: CPython',
    'Topic :: Software Development :: Libraries :: Python Modules',
    'Topic :: Scientific/Engineering :: Information Analysis',
    'Topic :: Text Processing :: Linguistic'
]


setup(name="datrie",
      version=__version__,
      description=DESCRIPTION,
      long_description=LONG_DESCRIPTION,
      author='Mikhail Korobov',
      author_email='kmike84@gmail.com',
      license=LICENSE,
      url='https://github.com/kmike/datrie',
      classifiers=CLASSIFIERS,
      ext_modules=[
          Extension("datrie", [
              'src/datrie.c',
              'src/cdatrie.c',
              'src/stdio_ext.c'
          ], libraries=['datrie'],
          include_dirs=['/usr/include/datrie'])
      ],

      python_requires=">=2.7, !=3.0.*, !=3.1.*, !=3.2.*, !=3.3.*",
      tests_require=["pytest", "hypothesis"])
