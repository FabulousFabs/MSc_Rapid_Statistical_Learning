'''
Leabra simulation class
'''

import os, string
import numpy as np

class simulation:
    def __init__(self, model):
        '''
        set working model
        '''

        self.model = model

    def __enter__(self):
        '''
        entry point for simulation object
        '''

        return self

    def __exit__(self, t, v, tb):
        '''
        exit point for simulation object
        '''

        pass

    def run(self):
        '''
        run a simulation of the model
        '''

        if self.model.compiled is False: raise AssertionError('Cannot run a simulation over an uncompiled model.')

        pass
