#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import absolute_import, unicode_literals, division
import random
import string
import timeit
import os
import zipfile
import pstats
import cProfile
#import psutil
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

def random_words(num):
    russian = 'абвгдеёжзиклмнопрстуфхцчъыьэюя'
    alphabet = russian + string.ascii_letters
    return [
        "".join([random.choice(alphabet) for x in range(random.randint(1,15))])
        for y in range(num)
    ]

def truncated_words(words):
    return [word[:4] for word in words]

WORDS100k = words100k()
MIXED_WORDS100k = truncated_words(WORDS100k)
NON_WORDS100k = random_words(100000)



def _alphabet(words):
    chars = set()
    for word in words:
        for ch in word:
            chars.add(ch)
    return "".join(sorted(list(chars)))

def bench(name, timer, descr='M ops/sec', op_count=0.1, repeats=3, runs=5):
    times = []
    for x in range(runs):
        times.append(timer.timeit(repeats))

    def op_time(time):
        return op_count*repeats / time

    min_time = min(times)
    mean_time = times[int((runs-1)/2)]

    print("%s: max=%0.3f%s, mean=%0.3f%s" % (
        name,
        op_time(min_time),
        descr,
        op_time(mean_time),
        descr,
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
    print('\n====== Benchmarks (100k unique unicode words) =======\n')

    tests = [
        ('__getitem__ (hits)', "for word in words: data[word]", 'M ops/sec', 0.1, 3),
        ('__contains__ (hits)', "for word in words: word in data", 'M ops/sec', 0.1, 3),
        ('__contains__ (misses)', "for word in words2: word in data", 'M ops/sec', 0.1, 3),
        ('__len__', 'len(data)', ' ops/sec', 1, 1),
        ('items()', 'list(data.items())', ' ops/sec', 1, 1),
        ('keys()', 'list(data.keys())', ' ops/sec', 1, 1),
        ('values()', 'list(data.values())', ' ops/sec', 1, 1),
    ]

    common_setup = """
from __main__ import create_trie, WORDS100k, NON_WORDS100k, MIXED_WORDS100k
words = WORDS100k
words2 = NON_WORDS100k
words3 = MIXED_WORDS100k
"""
    dict_setup = common_setup + 'data = dict((word, 1) for word in words);'
    trie_setup = common_setup + 'data = create_trie();'

    for test_name, test, descr, op_count, repeats in tests:
        t_dict = timeit.Timer(test, dict_setup)
        t_trie = timeit.Timer(test, trie_setup)

        bench('dict '+test_name, t_dict, descr, op_count, repeats)
        bench('trie '+test_name, t_trie, descr, op_count, repeats)


    # trie-specific benchmarks

    bench(
        'trie.iter_prefix_items (hits)',
        timeit.Timer(
            "for word in words:\n"
            "   for it in data.iter_prefix_items(word):\n"
            "       pass",
            trie_setup
        ),
    )

    bench(
        'trie.prefix_items (hits)',
        timeit.Timer(
            "for word in words: data.prefix_items(word)",
            trie_setup
        )
    )

    bench(
        'trie.prefix_items loop (hits)',
        timeit.Timer(
            "for word in words:\n"
            "    for it in data.prefix_items(word):pass",
            trie_setup
        )
    )

    bench(
        'trie.iter_prefixes (hits)',
        timeit.Timer(
            "for word in words:\n"
            "   for it in data.iter_prefixes(word): pass",
            trie_setup
        )
    )

    bench(
        'trie.iter_prefixes (misses)',
        timeit.Timer(
            "for word in words2:\n"
            "   for it in data.iter_prefixes(word): pass",
            trie_setup
        )
    )

    bench(
        'trie.iter_prefixes (mixed)',
        timeit.Timer(
            "for word in words3:\n"
            "   for it in data.iter_prefixes(word): pass",
            trie_setup
        )
    )

    bench(
        'trie.has_keys_with_prefix (hits)',
        timeit.Timer(
            "for word in words: data.has_keys_with_prefix(word)",
            trie_setup
        )
    )

    bench(
        'trie.has_keys_with_prefix (misses)',
        timeit.Timer(
            "for word in words2: data.has_keys_with_prefix(word)",
            trie_setup
        )
    )

    bench(
        'trie.longest_prefix (hits)',
        timeit.Timer(
            "for word in words: data.longest_prefix(word)",
            trie_setup
        )
    )

    bench(
        'trie.longest_prefix (misses)',
        timeit.Timer(
            "for word in words2: data.longest_prefix(word, default=None)",
            trie_setup
        )
    )

    bench(
        'trie.longest_prefix (mixed)',
        timeit.Timer(
            "for word in words3: data.longest_prefix(word, default=None)",
            trie_setup
        )
    )

def profiling():
    print('\n====== Profiling =======\n')
    trie = create_trie()
    WORDS = words100k()

#    def check_prefixes(trie, words):
#        for word in words:
#            for item in trie.iter_prefixes(word):
#                pass
#    cProfile.runctx("check_prefixes(trie, WORDS)", globals(), locals(), "Profile.prof")

    cProfile.runctx("check_trie(trie, WORDS)", globals(), locals(), "Profile.prof")

    s = pstats.Stats("Profile.prof")
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