'''
@description: Quick script to traverse raw data and collect all 4AFC data.
'''

import os, sys, string
from pathlib import Path

'''
setup
'''

flag_all = '--all' in sys.argv
flag_target = 'MEG' if '--MEG' in sys.argv else '2AFCW' if '--2AFCW' in sys.argv else '2AFCD' if '--2AFCD' in sys.argv else '4AFC'

dir_traverse = '/project/3018012.23/raw/'
target = '*_' + flag_target  + '.txt'
out = '/project/3018012.23/processed/combined/union_' + flag_target + '_' + str(flag_all) + '.txt'

'''
exclude pilots
'''

pilots = ['SABGU', 'KOINW', 'IQEXX', 'OGZRN', 'KNPVQ', 'WTOAI', 'EZNTM', 'QKXZX', 'VFCLU']

'''
utilities
'''

def read_txt(f, s = True):
    '''
    Read txt table
    '''
    
    tbl = []
    
    with open(str(f), 'r') as ftxt:
        con = ftxt.readlines()
        
        for i in range(len(con)):
            if i == 0 and s is True: continue # skip header
            tbl.append(con[i].replace('\n', '').split('\t'))
    
    return tbl

def mk_line(ins):
    return '\t'.join(ins) + '\n'

'''
traverse and collect
'''

print('Mode: aggregate.py --all=%s --%s' % (flag_all, flag_target))

i = 0

with open(out, 'w+') as master:
    for p in Path(dir_traverse).rglob(target):
        ppn = p.name.split('_')[0]
        if not flag_all and ppn in pilots: continue # skip pilots
        content = read_txt(p, s = True) if i > 0 else read_txt(p, s = False)
        
        for n in range(len(content)):
            if i > 0 or n > 0:
                content[n].insert(0, ppn)
            else:
                content[n].insert(0, 'ppn')
        
        for line in content: master.write(mk_line(line))
        
        i += 1

print('Done.')
    
    
