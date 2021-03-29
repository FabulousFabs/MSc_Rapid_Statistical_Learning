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

def read_txt_by(f, type = None, ppn = None):
    """Read txt table and fill NAs to fit template"""
    if type is None or ppn is None: return

    tbl = []
    items = []

    with open(f, 'r') as ftxt:
        con = ftxt.readlines()

        for i in range(len(con)):
            if i == 0: continue # skip header
            line = read_line_by(con[i], type = type, ppn = ppn)
            items.append(line[3])
            line[2] = str(items.count(line[3]) + (4 if type == '2AFCD' else 8 if type == '2AFCW' else 16))
            tbl.append(line)

    return tbl

def read_line_by(line, type = None, ppn = None):
    """Fill in line properly"""
    if type is None or ppn is None: return

    # id, speaker, variant, duration, file, pool, list, definition, sex, filler, correct, rt, index == 13 => 2AFCW
    # foil id, foil speaker, foil variant, foil duration                                            == 4 => 2AFCD
    # option 1, option 2, option 3, option 4                                                        == 4 => 4AFC
    # task, learning iteration, ppn                                                                 == 3 => additional flags
    full_line = ['N/A'] * 24
    full_line[0] = type
    full_line[1] = ppn
    full_line[2] = str(-1)

    # header:
    # task, ppn, learning iteration, id, speaker, variant, duration, file, pool, list, definition, sex, filler, correct, rt, index
    # foil id, foil speaker, foil variant, foil duration, option 1, option 2, option 3, option 4

    data = line.replace('\n', '').split('\t')

    if type == "2AFCW":
        full_line[3:16] = data[0:13]
    elif type == "2AFCD":
        full_line[3:12] = data[0:9]
        full_line[13:16] = data[13:16]
        full_line[16:20] = data[9:13]
    elif type == "4AFC":
        full_line[3:12] = data[0:9]
        full_line[13:16] = data[13:16]
        full_line[20:24] = data[9:13]

    return full_line

def preprocess_evolution():
    """Main function for aggregation of evolution data"""
    files = find_data(ins_evo, ext)

    with open(os.path.join(outs, target_evo), 'w+') as master:
        master.write(mk_line(['task', 'ppn', 'iteration', 'id', 'spkr', 'var', 'dur', 'f', 'pool', 'list', 'def', 'sex', 'filler', 'cor', 'rt', 'i', 'f_id', 'f_spkr', 'f_var', 'f_dur', 'o1', 'o2', 'o3', 'o4']))
        for i in range(len(files)):
            ppn, task = files[i].replace('.txt', '').split('_')
            content = read_txt_by(os.path.join(ins_evo, files[i]), type = task, ppn = ppn)
            for line in content: master.write(mk_line(line))
    print('--- All done. ---')

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 10 and arg[0:10] == '-aggregate':
                preprocess_aggregate()
            elif len(arg) >= 10 and arg[0:10] == '-evolution':
                preprocess_evolution()
