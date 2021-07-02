# script to aggregate all behavioural data into one file

import os, sys, string
from pathlib import Path

'''
setup
'''

dir_traverse = '/project/3018012.23/raw/'
target = '*_4AFC.txt'
out = '/project/3018012.23/processed/combined/unison_4AFC.txt'

'''
utilities
'''

def read_txt(f, s=True):
    """Read txt table"""
    tbl = []

    with open(f, 'r') as ftxt:
        con = ftxt.readlines()

        for i in range(len(con)):
            if i == 0 and s is True: continue # skip header
            tbl.append(con[i].replace('\n', '').split('\t'))

    return tbl

'''
traverse and collect
'''

i = 0

for p in Path(dir_traverse).rglob(target):
    i += 1
    print(p.name)
