'''
Quick script for testing the model implementation
'''

import os, string
import numpy as np
import leabra
import pmane_helper

pwd = '/users/fabianschneider/desktop/university/master/dissertation/project/simulation/'
spike_train = pmane_helper.load(os.path.join(pwd, 'spike_encoded', '1_1_1.npy'))

hippocampus = leabra.hippocampus.Model(load_model=os.path.join(pwd, 'models', 'template.npy'),
                                       input_shape=(spike_train.shape[0], spike_train.shape[1]),
                                       verbose=True,
                                       solver=leabra.solvers.Heuns)

#hippocampus = leabra.hippocampus.Model(input_shape=(spike_train.shape[0], spike_train.shape[1]),
#                                       verbose=True)
#hippocampus.save(os.path.join(pwd, 'models', 'template.npy'))

hippocampus.simulate(source=spike_train.flatten(), to=hippocampus.CH)
