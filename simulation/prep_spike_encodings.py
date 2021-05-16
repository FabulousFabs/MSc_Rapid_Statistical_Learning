'''
An implementation of cochlear spike encoding as per:

        Pan, Z., Chua, Y., Wu, J., Zhang, M., Li, H., & Ambikairajah, E. (2020). An efficient and perceptually motivated auditory neural encoding and decoding algorithm for spiking neural networks. Frontiers in Neuroscience, 13, e1420. DOI: http://dx.doi.org/10.3389/fnins.2019.01420

Note that, because of hippocampal modelling constraints, we do not use the exact
encoding scheme proposed by Pan et al. We have to cut down the threshold neuron
coding scheme employed by them so as not to overcomplicate the story too much
and we will also have to downsample stimuli in time substantially.

Run once, then use the .npy files produced.
'''

import os, sys, string, librosa
import numpy as np
import pmane, pmane_helper

audio_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/stimulus-creation/preprocessing-finalise/pcm/'
spike_folder = '/users/fabianschneider/desktop/university/master/dissertation/project/simulation/spike_encoded/'
ext = '.wav'

recordings = pmane_helper.find_files(audio_folder, ext)

for rec, i in zip(recordings, np.arange(len(recordings))):
    print('Encoding ' + str(round(i / len(recordings) * 100, 2)) + '%.\t\t', end='\r')

    '''
    Quick heads up: We know that given our setup, the longest stimulus
    will be 20x472. Hence, we should always pad everything to that length.
    For future reference: longest stimulus at 1371 is 4_8_4.wav
    '''

    M = np.zeros((20, 472))

    # encode
    audio, fs = librosa.load(os.path.join(audio_folder, rec))
    Tfn = pmane.compute_cochlear_response(audio, fs, simplified = True,
                                                     spectral_L = 128)
    M[:,0:Tfn.shape[1]] = Tfn

    # save
    fn = rec.split('.')[0] + ".npy"
    with open(os.path.join(spike_folder, fn), 'wb') as f:
        np.save(f, M)

print('All done. Please check the encoded .npy files.')
