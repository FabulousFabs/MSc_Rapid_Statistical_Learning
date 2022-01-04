'''
Quick script for testing the model implementation
'''

import os, string
import numpy as np
import leabra
import pmane_helper

''' Setup '''
pwd = '/users/fabianschneider/desktop/university/master/dissertation/project/simulation/'
spike_train = pmane_helper.load(os.path.join(pwd, 'spike_encoded', '1_1_1.npy'))

''' Build model '''
with leabra.model(verbose=True, progress=True) as model:
    #ECi, DG, CA3, CA1, ECo = model.build_recipe(leabra.hippocampus)
    #model.build_recipe(leabra.hippocampus)
    #A1 = model.neurons()
    ensemble_A = model.neurons(N=10, M=10, L='A', T=leabra.neurons.types.LIF)
    ensemble_B = model.neurons(N=10, M=10, L='B', T=leabra.neurons.types.LIF)

    A_to_B = model.synapses(pre=ensemble_A, post=ensemble_B, L='A_to_B', T=leabra.synapses.Full())
    B_to_A = model.synapses(pre=ensemble_B, post=ensemble_A, L='B_to_A', T=leabra.synapses.Full())

#''' Run model '''
#with leabra.simulation(model) as sim:
#    sim.run()
