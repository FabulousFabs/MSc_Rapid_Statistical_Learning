'''
Helper file for easy plots
'''

import numpy as np
import numpy.matlib
import matplotlib.pyplot as plt

def spike_train(spike_train=None, dt=1e-3):
    ''' Plot spike train '''

    if spike_train is None: return False

    plt.figure()
    plt.title('Spike train')
    plt.ylabel('Neurons')
    plt.xlabel('Time')

    spike_train[spike_train[:,:] == 0] = np.nan

    for i in range(spike_train.shape[0]):
        plt.scatter(np.arange(spike_train.shape[1]) * dt, spike_train[i,:] * i, marker='|', linewidths=0.5)

def show():
    ''' plt.show() handler so you don't have to import pyplot in main '''

    plt.show()
