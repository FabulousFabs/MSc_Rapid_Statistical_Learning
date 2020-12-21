# pipeline to take all of our stimuli and create assignments per participant
# this is done by crossing lists (levels 1-3) with pools (levels 1-3) such
# that we get 9 conditions with 80 items each (where items in pool 1 and 3
# are the different variants produced by one speaker, whereas items in pool
# 2 are one variant of each of the four speakers in that pool). essentially,
# this is how we manipulate variability along our two dimensions.

import os, sys, re
from pydub import AudioSegment
import numpy as np

stimuli_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-test/'
list_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/lists/'
speakers_file = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/speakers.txt'
audio_targets = '.wav'

n_lists = 1 # how many lists do we want to create (NOTE: we use one such list of assignments per participant)
n_speakers = 12
n_targets = 60
n_variants = 4

def preprocess_assignment():
    """Create pseudorandom assignment lists for stimuli"""
    recs = find_recordings(stimuli_folder, audio_targets)
    speakers = read_speakers(speakers_file)
    (speakers_m, speakers_f) = split_speakers(speakers)
    stimuli = np.zeros(shape=(n_speakers, n_targets, n_variants))

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
        outs = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\n'
        outs_learning = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\n'
        outs_4afc = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\n'
        outs_meg = 'var\tid\tspkr\tdur\tf\tpool_speaker\tlist_item\n'

        # create three randomised lists of targets
        stim = np.arange(1, (n_targets + 1), 1, dtype='int')
        lists = np.random.choice(stim, n_targets, replace=False).reshape(3, 20)

        # create three pseudorandomised pools of speakers (equal m:f split, hence pseudo)
        sf = np.array([speakers_f[n][0] for n in range(len(speakers_f))], dtype='int')
        sm = np.array([speakers_m[n][0] for n in range(len(speakers_m))], dtype='int')
        pools = np.concatenate((np.random.choice(sf, 6, replace=False).reshape(3, 2), np.random.choice(sm, 6, replace=False).reshape(3, 2)), axis=1)

        # list-wise creation of outs
        for n in range(1,4):
            lnp1 = get_outs_single(n, lists[n-1,:], 1, pools[0,:], range(1,5), stimuli)      # LNP1 crossing
            lnp2 = get_outs_multiple(n, lists[n-1,:], 2, pools[1,:], range(1,5), stimuli)    # LNP2 crossing
            lnp3 = get_outs_single(n, lists[n-1,:], 3, pools[2,:], range(1,5), stimuli)      # LNP3 crossing

            # save everything to master
            outs += lnp1 + lnp2 + lnp3

            # save only learning conditions
            if n == 1: outs_learning += lnp1
            if n == 2: outs_learning += lnp2

            # save only 4afc conditions
            outs_4afc += get_outs_single(n, lists[n-1,:], 1, pools[0,:], range(1,5), stimuli, beh=True)     # LNP1 crossing behavioural
            outs_4afc += get_outs_multiple(n, lists[n-1,:], 2, pools[1,:], range(1,5), stimuli, beh=True)   # LNP2 crossing behavioural
            outs_4afc += get_outs_single(n, lists[n-1,:], 3, pools[2,:], range(1,5), stimuli, beh=True)     # LNP3 crossing behavioural

            # save only meg conditions
            if n == 1: outs_meg += lnp1 + lnp2
            if n == 2: outs_meg += lnp1 + lnp2

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

def read_speakers(f):
    """Read speaker information"""
    speakers = []

    with open(f, 'r') as fspkr:
        sd = fspkr.readlines()

        for i in range(len(sd)):
            if i == 0: continue # skip header
            speakers.append(sd[i].replace('\n', '').split('\t'))

    return speakers

def split_speakers(s):
    """Split speaker list by sex"""
    (sm, sf) = ([], [])
    for spkr in s:
        if (spkr[1] == 'f'):
            sf.append(spkr)
        else:
            sm.append(spkr)
    return (sm, sf)

def get_outs_single(n, items, p, pool, v, stimuli, beh=False):
    """Create output string for single speaker types"""
    outs = ''

    if beh is False:
        c = 0
        for item in items:
            if (c > len(pool)-1): c = 0
            spkr = pool[c]
            for var in v:
                outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\n' % (
                                                            var,
                                                            item,
                                                            spkr,
                                                            stimuli[spkr-1,item-1,var-1],
                                                            '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                            p,
                                                            n
                                                         )
            c += 1
    else:
        c = 0
        for item in items:
            if (c > len(pool)-1): c = 0
            spkr = pool[c]
            var = np.random.randint(0, 3) # randint samples from a discrete uniform so best choice here
            outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\n' % (
                                                        var+1,
                                                        item,
                                                        spkr,
                                                        stimuli[spkr-1,item-1,var],
                                                        '_'.join([str(spkr), str(item), str(var+1)]) + '.wav',
                                                        p,
                                                        n
                                                     )
            c += 1

    return outs

def get_outs_multiple(n, items, p, pool, v, stimuli, beh=False):
    """Create output string for multiple speaker types"""
    outs = ''

    if beh is False:
        for item in items:
            for spkr in pool:
                var = np.random.choice(v, 1)[0]
                outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\n' % (
                                                            var,
                                                            item,
                                                            spkr,
                                                            stimuli[spkr-1,item-1,var-1],
                                                            '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                            p,
                                                            n
                                                         )
    else:
        for item in items:
            spkr = pool[np.random.randint(0, 3)]
            var = np.random.choice(v, 1)[0]
            outs += '%d\t%d\t%d\t%d\t%s\t%d\t%d\n' % (
                                                        var,
                                                        item,
                                                        spkr,
                                                        stimuli[spkr-1,item-1,var-1],
                                                        '_'.join([str(spkr), str(item), str(var)]) + '.wav',
                                                        p,
                                                        n
                                                     )
    return outs

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 5 and arg[0:4] == '--N=':
                n_lists = int(arg[4:])

    preprocess_assignment()
