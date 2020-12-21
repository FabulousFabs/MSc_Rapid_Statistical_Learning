# pipeline to copy files for a sham run of assignment (while we don't have the full
# list of stimuli yet - useless afterwards)

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

        # create three randomised lists of targets
        stim = np.arange(1, (n_targets + 1), 1, dtype='int')
        lists = np.random.choice(stim, n_targets, replace=False).reshape(3, 20)

        # create three pseudorandomised pools of speakers (equal m:f split, hence pseudo)
        sf = np.array([speakers_f[n][0] for n in range(len(speakers_f))], dtype='int')
        sm = np.array([speakers_m[n][0] for n in range(len(speakers_m))], dtype='int')
        pools = np.concatenate((np.random.choice(sf, 6, replace=False).reshape(3, 2), np.random.choice(sm, 6, replace=False).reshape(3, 2)), axis=1)

        # list-wise creation of outs
        for n in range(1,4):
            items = lists[n-1,:]
            outs += get_outs_single(n, items, 1, pools[0,:], range(1,5), stimuli)      # LNP1 crossing
            outs += get_outs_multiple(n, items, 2, pools[1,:], range(1,5), stimuli)    # LNP2 crossing
            outs += get_outs_single(n, items, 3, pools[2,:], range(1,5), stimuli)      # LNP3 crossing

        with open(os.path.join(list_folder, str(i) + '.txt'), 'w') as f:
            f.write(outs)
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

def get_outs_single(n, items, p, pool, v, stimuli):
    """Create output string for single speaker types"""
    outs = ''
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
    return outs

def get_outs_multiple(n, items, p, pool, v, stimuli):
    """Create output string for multiple speaker types"""
    outs = ''
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
    return outs

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 5 and arg[0:4] == '--N=':
                n_lists = int(arg[4:])

    preprocess_assignment()
