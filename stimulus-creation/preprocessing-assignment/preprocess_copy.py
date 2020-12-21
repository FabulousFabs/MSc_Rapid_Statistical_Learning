# pipeline to copy files for a sham run of assignment (while we don't have the full
# list of stimuli yet - useless afterwards)

import os, sys
import librosa
import soundfile as sf

copy_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-test/'
speaker_samples = 12
audio_targets = '.wav'

def preprocess_copy():
    """Find all recordings of one speaker and copy n-1 times"""
    recs = find_recordings(copy_folder, audio_targets)

    for rec in recs:
        audio, fs = librosa.load(os.path.join(copy_folder, rec))

        for i in range(speaker_samples - 1):
            n = i + 2

            fn = rec.split('_')
            fn[0] = str(n)
            fn = '_'.join(fn)

            sf.write(os.path.join(copy_folder, fn), audio, fs)

            print('--- Copy rec%s at %d. ---\t\t' % (rec, n), end='\r')

    print('All done. Copied all files %d times. See outputs.\t\t' % (speaker_samples - 1))
    return 0

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
            if len(arg) >= 5 and arg[0:4] == '--S=':
                speaker_samples = int(arg[4:])

    preprocess_copy()
