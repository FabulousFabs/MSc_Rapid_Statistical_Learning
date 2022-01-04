'''
Leabra hippocampal recipe
'''

import numpy as np

from leabra_recipe import recipe

class hippocampus(recipe):
    def __init__(self, model, args):
        '''
        build hippocampal circuit based on args
        '''

        super().__init__()

        self.model = model
        self.args = args

        self.shape_EC = self.vargxor('shape_EC', np.array([20, 472]))
        self.shape_DG = self.vargxor('shape_DG', np.array([20, 20]))
        self.shape_CA3 = self.vargxor('shape_CA3', np.array([8, 10]))
        self.shape_CA1 = self.vargxor('shape_CA1', np.array([10, 10]))

        
