'''
Leabra model class
'''

import os, string
import numpy as np

import leabra_neurons as neurons
import leabra_synapses as synapses

class model:
    def __init__(self, load_model=None, verbose=False, progress=True):
        '''
        initialisation of a model
        '''

        ''' debugging flags '''
        self.verbose = verbose
        self.progress = progress
        self.progress_tick = 0
        self.progress_ticks = np.array(['|', '/', '—', '\\', '|', '/', '—', '\\'])

        ''' initialisation of neuron/synapse structures '''
        self.neurons = np.array([], dtype=np.float)
        self.synapses = np.array([], dtype=np.float)

        if load_model is None:
            ''' build model from scratch '''
            self.compiled = False
            self.log('*** load_model=None specified. Building from scratch. ***')

        else:
            ''' load precompiled model '''
            self.compiled = True
            self.log('*** Loading precompiled model, load_model=%s.' % (load_model))

    def __enter__(self):
        '''
        entry point for with call
        '''

        return self

    def __exit__(self, t, v, tb):
        '''
        exit point for with call
        '''

        self.compiled = True

    def log(self, msg):
        '''
        log, if debugging is active
        '''

        if self.verbose is True: print(msg)

    def progress(self, msg):
        pass

    def build_recipe(self, recipe, force=False, **kwargs):
        '''
        add a prespecified structure from a recipe
        '''

        if self.compiled is True:
            if force is False: raise AssertionError('Trying to build a recipe into precompiled template with force=False.')
            raise RuntimeWarning('Force building recipe into precompiled model.')

        return recipe(self, kwargs)

    def neurons(self, N=1, M=1, L=None, T=neurons.types.LIF):
        '''
        add a population of neurons to the model
        '''

        if L is None: raise RuntimeWarning('Utilising unlabeled neurons in the model.')
        if N*M < 1: raise AssertionError('Trying to build <1 neurons in the model.')

        pass

    def synapses(self, pre=None, post=None, L=None, T=synapses.Full()):
        '''
        add synapses between two population of neurons
        '''

        if L is None: raise RuntimeWarning('Utilising unlabeled synapses in the model.')
        if pre is None: raise AssertionError('Cannot build synapses without presynaptic neurons.')
        if post is None: raise AssertionError('Cannot build synapses without postsynaptic neurons.')
