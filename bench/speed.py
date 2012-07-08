#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals, division
import gc
import timeit
import os
import zipfile
import pstats
import cProfile
import psutil
import datrie

def _get_memory(pid):
    process = psutil.Process(pid)
    return float(process.get_memory_info()[0]) / (1024 ** 2)

def words100k():
    zip_name = os.path.join(
        os.path.abspath(os.path.dirname(__file__)),
        'words100k.txt.zip'
    )
    zf = zipfile.ZipFile(zip_name)
    txt = zf.open(zf.namelist()[0]).read().decode('utf8')
    return txt.splitlines()

def _alphabet(words):
    chars = set()
    for word in words:
        for ch in word:
            chars.add(ch)
    return "".join(sorted(list(chars)))

def bench(name, timer, words_count, repeats=3, runs=5):
    times = []
    for x in range(runs):
        times.append(timer.timeit(repeats))

    def word_time(time):
        return words_count*repeats / time

    min_time = min(times)
    mean_time = times[int((runs-1)/2)]

    print("%s: max=%0.0fK words/sec, mean=%0.0fK words/sec" % (
        name,
        word_time(min_time)/1000,
        word_time(mean_time)/1000,
    ))

def create_trie():
    words = words100k()
    trie = datrie.new(_alphabet(words))
#    trie = datrie.new(ranges = [
#        ("'", "'"),
#        ('A', 'z'),
#        ('А', 'я'),
#    ])

    for word in words:
        trie[word] = 1
    return trie

def check_trie(trie, words):
    value = 0
    for word in words:
        value += trie[word]
    if value != len(words):
        raise Exception()

def benchmark():
    print('\n====== Benchmark =======\n')

    test = "for word in WORDS: container[word]"
    common_setup = """
from __main__ import words100k, create_trie
WORDS = words100k()
"""
    dict_setup = common_setup + 'container = dict((word, 1) for word in WORDS);'
    trie_setup = common_setup + 'container = create_trie();'

    t_dict = timeit.Timer(test, dict_setup)
    t_trie = timeit.Timer(test, trie_setup)

    bench('dict __getitem__', t_dict, 100000)
    bench('trie __getitem__', t_trie, 100000)

def profiling():
    print('\n====== Profiling =======\n')
    trie = create_trie()
    WORDS = words100k()
    #cProfile.run("trie = create_trie(); check_trie(trie, WORDS)")
    cProfile.runctx("check_trie(trie, WORDS)", globals(), locals(), "Profile.prof")

    s = pstats.Stats("Profile.prof")
    #s.print_stats()
    s.strip_dirs().sort_stats("time").print_stats(10)

#def memory():
#    gc.collect()
#    _memory = lambda: _get_memory(os.getpid())
#    initial_memory = _memory()
#    trie = create_trie()
#    gc.collect()
#    trie_memory = _memory()
#
#    del trie
#    gc.collect()
#    alphabet, words = words100k()
#    words_dict = dict((word, 1) for word in words)
#    del alphabet
#    del words
#    gc.collect()
#
#    dict_memory = _memory()
#    print('initial: %s, trie: +%s, dict: +%s' % (
#        initial_memory,
#        trie_memory-initial_memory,
#        dict_memory-initial_memory,
#    ))

if __name__ == '__main__':
    create_trie()
    benchmark()
    #profiling()
    #memory()
    print('\n~~~~~~~~~~~~~~\n')