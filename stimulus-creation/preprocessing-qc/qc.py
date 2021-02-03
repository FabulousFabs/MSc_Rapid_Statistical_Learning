# quick script for quality to control to refactor file names such that
# we can quickly go through all items grouped together for a final check
# of whether or not everything's a-ok before we finalise

import os, sys
import librosa
import soundfile as sf

copy_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-qc/ins/'
item_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-qc/by_item/'
speaker_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-qc/by_speaker/'
audio_targets = '.wav'

def preprocess_qc_forward():
    """Find all recordings, copy, rename"""
    recs = find_recordings(copy_folder, audio_targets)

    n = 0

    for rec in recs:
        n = n + 1
        audio, fs = librosa.load(os.path.join(copy_folder, rec))

        fo = rec.split('_')
        fn = '_'.join([fo[1], fo[0], fo[2]])
        sf.write(os.path.join(item_folder, fn), audio, fs)

        print('--- Forward pass %d per cent. ---\t\t' % (round(n / len(recs) * 100, 2)), end='\r')

    print('All done (forwards). See outputs folder.\t\t')

def preprocess_qc_backward():
    """Find recordings, copy, rename"""
    recs = find_recordings(item_folder, audio_targets)

    n = 0

    for rec in recs:
        n = n + 1
        audio, fs = librosa.load(os.path.join(item_folder, rec))

        fo = rec.split('_')
        fn = '_'.join([fo[1], fo[0], fo[2]])
        sf.write(os.path.join(speaker_folder, fn), audio, fs)

        print('--- Backward pass %d per cent. ---\t\t' % (round(n / len(recs) * 100, 2)), end='\r')

    print('All done (backwards). See outputs folder.')

def find_recordings(f, t):
    """Grab all recordings with extension t from f"""
    af = os.listdir(f)
    at = []
    for f in af:
        if f.endswith(t):
            at.append(f)
    return at

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 8 and arg[0:8] == '-forward':
                preprocess_qc_forward()
            elif len(arg) >= 9 and arg[0:9] == '-backward':
                preprocess_qc_backward()
