'''
Leabra recipe class
'''

import numpy as np

class recipe:
    def __init__(self, model=None, args={}):
        '''
        throw away constructor in case recipe is underspecified
        '''

        self.model = model
        self.args = args

        pass

    def tick(self, model):
        '''
        throw away tick function in case recipe is underspecified
        '''

        pass

    def vargxor(self, key, xor):
        '''
        check optional argument against default value
        '''

        if key in self.args: return self.args[key]
        return xor
