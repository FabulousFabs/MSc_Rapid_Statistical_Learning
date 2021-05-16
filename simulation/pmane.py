'''
An implementation of cochlear spike encoding as per:

        Pan, Z., Chua, Y., Wu, J., Zhang, M., Li, H., & Ambikairajah, E. (2020). An efficient and perceptually motivated auditory neural encoding and decoding algorithm for spiking neural networks. Frontiers in Neuroscience, 13, e1420. DOI: http://dx.doi.org/10.3389/fnins.2019.01420

Note that, because of hippocampal modelling constraints, we do not use the exact
encoding scheme proposed by Pan et al. We have to cut down the threshold neuron
coding scheme employed by them so as not to overcomplicate the story too much
and we will also have to downsample stimuli in time substantially.

Nevertheless, I am leaving the full functionality in here for future reference.
'''

import os, sys, string
import numpy as np
import numpy.matlib
import librosa

def make_wavelet(F, fs, n_cycles = 5):
    ''' Returns length, time vector and complex morlet wavelet at F with n_cycles '''
    ''' Watch out for potential undersampling tho '''

    L = (1 / F) * n_cycles
    t = np.arange(-L/2, L/2+(1/fs), 1/fs)

    csw = np.exp(1j * 2 * np.pi * F * t)
    win = np.hanning(t.shape[0])
    csw = csw * win

    return (len(csw), t, csw)

def get_CQT_freq(F0 = 15, Fm = 8000, K = 20):
    ''' Returns centre frequencies and bandwidths of CQT as per Brown et al. 91/92 papers '''
    ''' Note that the equation is slightly modified for fixed K. Ergo, we compute b not K. '''

    b = np.abs(K / np.log2(F0 / Fm))
    Q = (2 ** (1 / b) - 1) ** (-1)

    k = np.arange(K)
    Fk = F0 * (2 ** (k / b))
    Bk = Fk / Q

    return (Fk, Bk)

def do_convolve(signal, kernel, L = None, pad_left = 0, pad_right = 0):
    ''' Convolve signal with kernel in time and return '''

    if L is None: L = kernel.shape[0]

    padding = np.floor(L / 2).astype(np.int)
    padded = np.pad(signal, (padding, padding), 'constant', constant_values = (pad_left, pad_right))
    convolved = np.zeros(signal.shape[0]).astype(np.complex)

    for k in np.arange(signal.shape[0]):
        convolved[k] = np.dot(padded[k:k+L], kernel)

    return convolved

def do_frame_tfs(convol, l = 64, pad = 0.0+0j):
    ''' Compute spectral energy in striding windows '''

    s = int(l / 2)
    L = convol.shape[0]
    padding = int(L % s)
    padded = np.pad(convol, (0, padding), 'constant', constant_values = (0, pad))
    K = int(padded.shape[0] / s)
    E = np.zeros(K)

    for k in np.arange(K):
        E[k] = 10*np.log(np.sum(np.abs(convol[k*s:(k*s+l)])) + 1e-27)

    return E, l

def get_simultaneous_mask(Fk, Ek):
    ''' Compute simultaneous mask for frequency/amplitude thresholds '''

    tm = np.zeros((Ek.shape[0], Ek.shape[1])).astype(np.float)
    Taf = 3.64 * (Fk / 1000) ** -0.8 - 6.5 * np.exp(-0.6 * (Fk / 1000 - 3.3) ** 2) + 0.001 * (Fk / 1000) ** 4

    for i in range(Ek.shape[1]):
        for j in range(Ek.shape[0]):
            if Ek[j,i] > Taf[j]: tm[j,i] = 1

    return tm

def get_temporal_mask(Ek, fs, l, c = 0.2):
    ''' Compute temporal mask for event decay thresholds '''

    tm = np.zeros((Ek.shape[0], Ek.shape[1])).astype(np.float)
    last_events = np.zeros(Ek.shape[0]).astype(np.float)
    last_indices = np.ones(Ek.shape[0]).astype(np.float) * 10e3

    for i in range(Ek.shape[1]):
        ds = ((c ** (last_indices * l / fs)) * last_events) - Ek[:,i]
        for j in range(ds.shape[0]):
            if ds[j] < 0:
                last_events[j] = Ek[j,i]
                last_indices[j] = i
                tm[j,i] = 1

    return tm

def get_spike_timings(Ek, thresholds_n = 10):
    ''' Compute spike timings for encoding neurons '''

    thresholds = np.arange(0, 1, 1 / thresholds_n)
    encoding_neurons = int(thresholds_n * 2)
    Tfn = np.zeros((int(Ek.shape[0] * encoding_neurons), Ek.shape[1]))

    for i in range(Ek.shape[0]):
        Ek[i,:] = Ek[i,:] / (np.max(Ek[i,:]) + 1e-27)
        last_step = 0

        for j in range(Ek.shape[1]):
            this_step = np.where(thresholds < (Ek[i,j] * np.ones(thresholds_n)))[0]
            if this_step.shape[0] > 0:
                this_step = np.argmax(this_step)
                if this_step > last_step:
                    Tfn[int(i*encoding_neurons+this_step),j] = 1
                    last_step = this_step
                elif this_step < last_step:
                    Tfn[int(i*encoding_neurons+thresholds_n+this_step),j] = 1
                    last_step = this_step

    return Tfn

def get_spikes(Ek, theta=0.6, eta=1e-27):
    ''' Returns spike matrix as per threshold theta '''

    Tfn = np.zeros((Ek.shape[0], Ek.shape[1]))
    Ek = Ek / (np.max(Ek, axis=1).reshape(Ek.shape[0], 1) + eta)
    Tfn[np.where(Ek >= theta)] = 1

    return Tfn

def compute_cochlear_response(y, fs, simplified = True,
                                     spike_theta = 0.6,
                                     spike_eta = 1e-27,
                                     cqt_F0 = 15,
                                     cqt_Fm = 8000,
                                     cqt_K = 20,
                                     wv_cycles = 5,
                                     spectral_L = 64,
                                     temporal_mask_c = 0.2):
    ''' Returns the frequency responses in time for a cochlea '''
    ''' Note simplified is what we use in our simulations '''

    # compute centre frequencies
    Fk = get_CQT_freq(F0=cqt_F0, Fm=cqt_Fm, K=cqt_K)[0]
    Ek = np.array([])

    # compute spectral energy
    for fk in Fk:
        L, t, kernel = make_wavelet(fk, fs, n_cycles=wv_cycles)
        filtered = do_convolve(y, kernel, L = L)
        E, l = do_frame_tfs(filtered, l = spectral_L)
        Ek = np.append(Ek, np.array([E]), axis = 0) if Ek.shape[0] > 0 else np.array([E])

    # compute simultaneous masking
    Taf = get_simultaneous_mask(Fk, Ek)

    # compute temporal masking
    Yn = get_temporal_mask(Ek, fs, l, c = temporal_mask_c)

    if simplified is True:
        # no timing and threshold encoding
        M = get_spikes(Ek, theta = spike_theta, eta = spike_eta)
        Tfn = Taf * Yn * M
    else:
        # full timing and threshold encoding
        M = Taf * Yn * Ek
        Tfn = get_spike_timings(M)

    return Tfn
