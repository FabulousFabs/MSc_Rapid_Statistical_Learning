# pipeline to take all of our stimuli and create assignments per participant
# this is done by crossing lists (levels 1-3) with pools (levels 1-3) such
# that we get 9 conditions with 80 items each (where items in pool 1 and 3
# are the different variants produced by one speaker, whereas items in pool
# 2 are one variant of each of the four speakers in that pool). essentially,
# this is how we manipulate variability along our two dimensions.

import os, sys
from pydub import AudioSegment
import numpy as np

stimuli_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-test/'
list_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/lists/'
speakers_file = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/speakers.txt'
definitions_file = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/definitions.txt'
fillers_file = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/fillers.txt'
audio_targets = '.wav'

n_lists = 1 # how many lists do we want to create (NOTE: we use one such list of assignments per participant)
n_speakers = 12
n_targets = 60
n_variants = 4

def preprocess_assignment():
    """Create pseudorandom assignment lists for stimuli"""
    recs = find_recordings(stimuli_folder, audio_targets)
    speakers = read_txt(speakers_file)
    (speakers_m, speakers_f) = split_speakers(speakers)
    stimuli = np.zeros(shape=(n_speakers, n_targets, n_variants))
    definitions = read_txt(definitions_file)
    fillers = read_txt(fillers_file)
    ans_none = 41

    for rec in recs:
        # get stimulus durations in ms
        audio = AudioSegment.from_wav(os.path.join(stimuli_folder, rec))
        props = rec.split('.')
        props = ''.join(props[:-1]).split('_')
        stimuli[int(props[0])-1,int(props[1])-1,int(props[2])-1] = len(audio)
        print('--- Read %d-%d-%d. ---\t\t' % (int(props[0]),int(props[1]),int(props[2])), end='\r')
    print('Completed reading all stimuli data.\t\t')

    for i in range(n_lists):
        """
        table:
            1) stimulus variant
            2) stimulus id
            3) stimulus speaker
            4) stimulus duration
            5) stimulus file
            6) pool (speaker)
            7) list (item)
        """
        outs = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\tdef\n'
        outs_learning = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\tdef\n'
        outs_4afc = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\tdef\n'
        outs_meg = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\tdef\n'

        # create three randomised lists of targets
        stim = np.arange(1, (n_targets + 1), 1, dtype='int')
        lists = np.random.choice(stim, n_targets, replace=False).reshape(3, 20)

        # create corresponding lists of definitions
        defs = np.arange(1, (len(definitions) + 1), 1, dtype='int')
        lists_opts = np.zeros(n_targets)
        lists_opts[0:len(definitions)] = np.random.choice(defs, len(definitions), replace=False)
        lists_opts[len(definitions):] = ans_none
        ans = lists_opts.reshape(3, 20)

        # create three pseudorandomised pools of speakers (equal m:f split, hence pseudo)
        sf = np.array([speakers_f[n][0] for n in range(len(speakers_f))], dtype='int')
        sm = np.array([speakers_m[n][0] for n in range(len(speakers_m))], dtype='int')
        pools = np.concatenate((np.random.choice(sf, 6, replace=False).reshape(3, 2), np.random.choice(sm, 6, replace=False).reshape(3, 2)), axis=1)

        # list-wise creation of outs
        for n in range(1,4):
            lnp1 = get_outs_single(n, lists[n-1,:], ans[n-1,:], 1, pools[0,:], range(1,5), stimuli)      # LNP1 crossing
            lnp2 = get_outs_multiple(n, lists[n-1,:], ans[n-1,:], 2, pools[1,:], range(1,5), stimuli)    # LNP2 crossing
            lnp3 = get_outs_single(n, lists[n-1,:], ans[n-1,:], 3, pools[2,:], range(1,5), stimuli)      # LNP3 crossing

            # save everything to master
            outs += lnp1 + lnp2 + lnp3

            # save only learning conditions
            if n == 1: outs_learning += lnp1
            if n == 2: outs_learning += lnp2

            # save only 4afc conditions
            outs_4afc += get_outs_single(n, lists[n-1,:], ans[n-1,:], 1, pools[0,:], range(1,5), stimuli, beh=True)     # LNP1 crossing behavioural
            outs_4afc += get_outs_multiple(n, lists[n-1,:], ans[n-1,:], 2, pools[1,:], range(1,5), stimuli, beh=True)   # LNP2 crossing behavioural
            outs_4afc += get_outs_single(n, lists[n-1,:], ans[n-1,:], 3, pools[2,:], range(1,5), stimuli, beh=True)     # LNP3 crossing behavioural

            # save only meg conditions
            if n == 1: outs_meg += lnp1 + lnp3
            if n == 2: outs_meg += lnp2 + lnp3

        # write master
        with open(os.path.join(list_folder, str(i) + '.txt'), 'w') as f:
            f.write(outs)

        # write learning
        with open(os.path.join(list_folder, str(i) + '_learning.txt'), 'w') as f:
            f.write(outs_learning)

        # write 4afc
        with open(os.path.join(list_folder, str(i) + '_4afc.txt'), 'w') as f:
            f.write(outs_4afc)

        # write meg
        with open(os.path.join(list_folder, str(i) + '_meg.txt'), 'w') as f:
            f.write(outs_meg)

        print('--- List %d/%d done. ---\t\t' % (i+1, n_lists), end='\r')
    print('Completed creating all lists.\t\t')

def find_recordings(f, t):
    """Grab all recordings with extension t from f"""
    af = os.listdir(f)
    at = []

    for f in af:
        if f.endswith(t):
            at.append(f)

    return at

def read_txt(f):
    """Read txt table"""
    tbl = []

    with open(f, 'r') as ftxt:
        con = ftxt.readlines()

        for i in range(len(con)):
            if i == 0: continue # skip header
            tbl.append(con[i].replace('\n', '').split('\t'))

    return tbl

def split_speakers(s):
    """Split speaker list by sex"""
    (sm, sf) = ([], [])
    for spkr in s:
        if (spkr[1] == 'f'):
            sf.append(spkr)
        else:
            sm.append(spkr)
    return (sm, sf)

def draw_ans(k, all):
    """@deprecated: Draw answer options for definition"""
    ans = np.array([k], dtype='int')

    while ans.shape[0] < 4:
        opt = np.random.choice(all, 1)
        if opt not in ans: ans = np.append(ans, opt)

    return ans[1:]


def get_outs_single(n, items, ans, p, pool, v, stimuli, beh=False):
    """Create output string for single speaker types"""
    outs = ''

    if beh is False:
        c = 0
        for item, opt in zip(items, ans):
            if (c > len(pool)-1): c = 0
            spkr = pool[c]
            for var in v:
                outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\n' % (
                                                            var,
                                                            item,
                                                            spkr,
                                                            stimuli[spkr-1,item-1,var-1],
                                                            '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                            p,
                                                            n,
                                                            opt
                                                         )
            c += 1
    else:
        c = 0
        for item, opt in zip(items, ans):
            if (c > len(pool)-1): c = 0
            spkr = pool[c]
            var = np.random.randint(0, 3) # randint samples from a discrete uniform so best choice here
            outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\n' % (
                                                        var+1,
                                                        item,
                                                        spkr,
                                                        stimuli[spkr-1,item-1,var],
                                                        '_'.join([str(spkr), str(item), str(var+1)]) + '.wav',
                                                        p,
                                                        n,
                                                        opt
                                                     )
            c += 1

    return outs

def get_outs_multiple(n, items, ans, p, pool, v, stimuli, beh=False):
    """Create output string for multiple speaker types"""
    outs = ''

    if beh is False:
        for item, opt in zip(items, ans):
            for spkr in pool:
                var = np.random.choice(v, 1)[0]
                outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\n' % (
                                                            var,
                                                            item,
                                                            spkr,
                                                            stimuli[spkr-1,item-1,var-1],
                                                            '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                            p,
                                                            n,
                                                            opt
                                                         )
    else:
        for item, opt in zip(items, ans):
            spkr = pool[np.random.randint(0, 3)]
            var = np.random.choice(v, 1)[0]
            outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\n' % (
                                                        var,
                                                        item,
                                                        spkr,
                                                        stimuli[spkr-1,item-1,var-1],
                                                        '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                        p,
                                                        n,
                                                        opt
                                                     )
    return outs

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 5 and arg[0:4] == '--N=':
                n_lists = int(arg[4:])

    preprocess_assignment()
