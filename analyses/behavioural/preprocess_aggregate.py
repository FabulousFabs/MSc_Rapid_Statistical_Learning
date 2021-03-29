# script to aggregate all behavioural data into one file

import os, sys, string

ins = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/data/'
ins_evo = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/data_evolution/'
outs = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/'
target = 'aggregate.txt'
target_evo = 'aggregate_evolution.txt'
ext = '.txt'

def preprocess_aggregate():
    """Main function for aggregation"""
    files = find_data(ins, ext)

    with open(os.path.join(outs, target), 'w+') as master:
        for i in range(len(files)):
            ppn = files[i].split('_')[0]
            content = read_txt(os.path.join(ins, files[i]), s=True) if i > 0 else read_txt(os.path.join(ins, files[i]), s=False)
            for n in range(len(content)):
                if i > 0 or n > 0:
                    content[n].insert(0, ppn)
                else:
                    content[n].insert(0, 'ppn')
            for line in content: master.write(mk_line(line))
    print('--- All done. ---')

def find_data(f, t):
    """Grab all files with extension t from f"""
    af = os.listdir(f)
    at = []

    for f in af:
        if f.endswith(t):
            at.append(f)

    return at

def read_txt(f, s=True):
    """Read txt table"""
    tbl = []

    with open(f, 'r') as ftxt:
        con = ftxt.readlines()

        for i in range(len(con)):
            if i == 0 and s is True: continue # skip header
            tbl.append(con[i].replace('\n', '').split('\t'))

    return tbl

def mk_line(ins):
    """Make writeable line from array"""
    return '\t'.join(ins) + '\n'

def preprocess_evolution():
    """Main function for aggregation of evolution data"""
    files = find_data(ins, ext)

    with open()

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 10 and arg[0:10] == '-aggregate':
                preprocess_aggregate()
            elif len(arg) >= 10 and arg[0:10] == '-evolution':
                preprocess_evolution()
