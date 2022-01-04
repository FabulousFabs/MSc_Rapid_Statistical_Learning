'''
Leabra neurons
'''

import numpy as np

class types:
    '''
    Super class for all neuron types
    '''

    def __init__(self):
        ''' register '''
        self.LIF = LIF()


class neurons:
    '''
    Super class for all neurons to implement vectorised versions of parameters, with details as per:

        Ketz, N., Morkonda, S.G., & O'Reilly, R.C. (2013). Theta coordinated error-driven learning in the hippocampus. PLoS Computational Biology, 9, e1003067. DOI: http://dx.doi.org/10.1371/journal.pcbi.1003067
    '''

    def __init__(self):
        ''' full vector '''
        self.vector = np.zeros((1, 25)).astype(np.float)

        ''' types '''
        self.LIF = 0

        ''' common fffb setup '''
        self.n = 0.0
        self.y = 0.0
        self.g_i_bar = 1.5
        self.ff_gain = 1.0
        self.ff0 = 0.0
        self.fb_gain = 0.5
        self.ff = 0.0
        self.fb = 0.0
        self.avg_ss = 0.0
        self.avg_s = 0.0
        self.avg_m = 0.0
        self.avg_l = 0.0
        self.avg_ef = 0.0

        ''' fill in vector '''
        self.vector[1] = self.n
        self.vector[2] = self.y
        self.vector[3] = self.g_i_bar
        self.vector[4] = self.ff_gain
        self.vector[5] = self.ff0
        self.vector[6] = self.fb_gain
        self.vector[7] = self.ff
        self.vector[8] = self.fb
        self.vector[9] = self.avg_ss
        self.vector[10] = self.avg_s
        self.vector[11] = self.avg_m
        self.vector[12] = self.avg_l
        self.vector[13] = self.avg_ef

    @property
    def vectorised(self):
        return self.vector

    def ff(self, neurons):
        '''
        Feedforward inhibition as per:
        '''

        return neurons[:,3] * (neurons[:,0] - neurons[:,4])

    def fb(self, neurons, dt=1e-3):
        '''
        Feedback inhibition as per:
        '''

        return neurons[:,7] + dt * (neurons[:,5] * neurons[:,1] - neurons[:,7])

    def g_i(self, neurons):
        '''
        Inhibitory competition:

            g_i(t) =
        '''

        return neurons[:,2] * (neurons[:,6] + neurons[:,7])

class LIF(neurons):
    '''
    Leaky Integrate-and-Fire neurons taken from:

        Teeter, C., Iyer, R., Menon, V., Gouwens, N., Feng, D., Berg, J., Szafer, A., Cain, N., Zeng, H., Hawrylycz, M., Koch, C., & Mihalas, S. (2018). Generalized leaky integrate-and-fire models classify multiple neuron types. Nature Communications, 9, e709. DOI: http://dx.doi.org/10.1038/s41467-017-02717-4
    '''

    def __init__(self):
        '''
        Default parameters for excitatory neuron_2 detailed in paper.
        '''

        self.E_l = -75.5        # mV
        self.th_i = -47.2       # mV
        self.d_th_i = 27.8      # mV
        self.E_syn = 0.0        # mV
        self.R = 177.0          # MO
        self.C = 107.0          # pF
        self.g = 40.0           # nS
        self.tau = 19.0         # ms
        self.del_t = 6.55       # ms

        self.vector[0] = self.LIF
        self.vector[13] = self.E_l
        self.vector[14] = self.E_l
        self.vector[15] = self.th_i
        self.vector[16] = self.d_th_i
        self.vector[17] = self.E_syn
        self.vector[18] = self.R
        self.vector[19] = self.C
        self.vector[20] = self.g
        self.vector[21] = self.tau
        self.vector[22] = self.del_t

    def dVdt(self, kwargs):
        pass


class AdEx(neurons):
    def __init__(self):
        pass

class Izhikevich(neurons):
    def __init__(self):
        pass
