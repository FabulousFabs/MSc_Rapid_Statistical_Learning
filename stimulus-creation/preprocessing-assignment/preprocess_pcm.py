# quick script to downsample to PCM16 because, for reasons unknown, NeuroBS
# has a quite apt name because Presentation simply doesn't support 32PCM.
# downsamples to 2byte 16PCM.

import os
import librosa
import soundfile as sf

all_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-test/'
out_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-test-16/'
audio_targets = '.wav'
target_pcm = 'PCM_16'

def preprocess_pcm():
    """Find all recordings of our speakers and downsample to PCM16"""
    recs = find_recordings(all_folder, audio_targets)
    n = 1

    for rec in recs:
        audio, fs = librosa.load(os.path.join(all_folder, rec))
        sf.write(os.path.join(out_folder, rec), audio, fs, subtype=target_pcm)
        print('--- Preprocessing downsample: ' + str(round(n / len(recs) * 100, 2)) + '% done. ---\t\t', end='\r')
        n += 1
    print('Downsampling completed. Please check the output folders to confirm.')

def find_recordings(f, t):
    """Grab all recordings with extension t from f"""
    af = os.listdir(f)
    at = []
    for f in af:
        if f.endswith(t):
            at.append(f)
    return at

if __name__ == '__main__':
    preprocess_pcm()
