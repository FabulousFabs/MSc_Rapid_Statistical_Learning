# quick script to sanity check our lists

import os, sys, string

list_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/lists/'
ppn = 'AKPPR_learning'

def qc_assignment():
    """Plot spkrs pools and lists for all items in a given input file for sanity checks"""
    list = read_txt(os.path.join(list_folder, ppn + '.txt'))
    items = {}
    for i in range(1, 61): items[str(i)] = {'spkrs': [], 'pools': [], 'lists': []}

    for item in list:
        id = str(item[1])
        spkr = int(item[2])
        pool = int(item[5])
        list = int(item[6])

        if spkr not in items[id]['spkrs']: items[id]['spkrs'].append(spkr)
        if pool not in items[id]['pools']: items[id]['pools'].append(pool)
        if list not in items[id]['lists']: items[id]['lists'].append(list)

    print('Item\tSpkrs\tPools\tLists')
    for i in range(1, 61):
        s = str(i)
        print(
            str(i) + '\t' +
            (','.join(str(v) for v in items[s]['spkrs'])) + '\t' +
            (','.join(str(v) for v in items[s]['pools'])) + '\t' +
            (','.join(str(v) for v in items[s]['lists']))
            )


def read_txt(f):
    """Read txt table"""
    tbl = []

    with open(f, 'r') as ftxt:
        con = ftxt.readlines()

        for i in range(len(con)):
            if i == 0: continue # skip header
            tbl.append(con[i].replace('\n', '').split('\t'))

    return tbl

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 7 and arg[0:6] == '--ppn=':
                ppn = arg[6:]

    qc_assignment()
