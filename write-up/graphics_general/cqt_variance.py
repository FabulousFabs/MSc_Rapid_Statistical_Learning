# script to get normalised CQTs to compare three speakers
# saying one word to exemplify the issue we're tackling in
# this project
# this used to be a MATLAB script but, quite frankly, that
# code was even worse than this so I took a minute to re-
# write at least a somewhat workable solution here

import os, sys
import numpy as np
import matplotlib.pyplot as plt
import librosa
from librosa import display, amplitude_to_db

speakers = np.array([1,2,3], dtype='int')
item = 1
num = 2

audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-assignment/full-done/'
figures_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/write-up/graphics_general/stash/cqts/'

def compute_cqts():
    '''
    compute the CQTs for our targets and save spectrograms
    '''

    audio1, fs1 = load_audio(0)
    audio2, fs2 = load_audio(1)
    audio3, fs3 = load_audio(2)
    audio1, audio2, audio3 = pad_audio(audio1, audio2, audio3)

    get_spectrograms([[audio1, fs1, 0], [audio2, fs2, 1], [audio3, fs3, 2]])

def load_audio(s):
    '''
    load file for specified speaker
    '''

    return librosa.load(os.path.join(audio_folder, '_'.join([str(speakers[s]), str(item), str(num)]) + '.wav'))

def pad_audio(a1, a2, a3):
    '''
    zero-padding at right margin of all audio files
    '''

    L = np.array([len(a1), len(a2), len(a3)])
    return (np.pad(a1, (0, np.max(L)-L[0]), 'constant', constant_values=(0,)), np.pad(a2, (0, np.max(L)-L[1]), 'constant', constant_values=(0,)), np.pad(a3, (0, np.max(L)-L[2]), 'constant', constant_values=(0,)))

def get_spectrograms(all):
    '''
    compute, plot, save
    '''
    
    for arr in all:
        fig, ax = plt.subplots()
        C = np.abs(librosa.cqt(arr[0], sr=arr[1]))
        img = librosa.display.specshow(librosa.amplitude_to_db(C, ref=np.max), sr=arr[1], x_axis='time', y_axis='cqt_hz', ax=ax, cmap='jet')
        ax.set_title('Constant-Q power spectrum speaker_' + str(speakers[arr[2]]) + '')
        fig.colorbar(img, ax=ax, format="%+2.0f dB")
        plt.savefig(os.path.join(figures_folder, '_'.join([str(speakers[arr[2]]), str(item), str(num)]) + '.png'))

if __name__ == '__main__':
    if len(sys.argv) >= 1:
        for arg in sys.argv[1:]:
            if len(arg) >= 5 and arg[0:4] == '--i=':
                item = int(arg[4:])
            elif len(arg) == 5 and arg[0:4] == '--n=':
                num = int(arg[4:])
            elif len(arg) >= 6 and arg[0:5] == '--s1=':
                speakers[0] = int(arg[5:])
            elif len(arg) >= 6 and arg[0:5] == '--s2=':
                speakers[1] = int(arg[5:])
            elif len(arg) >= 6 and arg[0:5] == '--s3=':
                speakers[2] = int(arg[5:])
            elif len(arg) == 4 and arg[0:4] == '-cqt':
                compute_cqts()
