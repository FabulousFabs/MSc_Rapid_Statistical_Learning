'''
Connectivity types as per

    Schapiro, A.C., Turk-Browne, N.B., Botvinick, M.M., & Norman, K.A. (2017). Complementary learning systems within the hippocampus: A neural network modelling approach to reconciling episodic memory with statistical learning. Philosophical Transactions of the Royal Society B: Biological Sciences, 372, e20160049. DOI: http://dx.doi.org/10.1098/rstb.2016.0049
'''

import numpy as np
import numpy.matlib

class M_t_N:
    '''
    NOTE: This class is not vectorised and highly inefficient.
    Unless absolutely necessary, use One_t_One.
    '''

    def __init__(self, M=1, N=1):
        self.M = M
        self.N = N

    def synapses(self, pre, post, wrange, fibres, lr):
        ''' Compute sparse MxN synapses '''

        synapses = np.empty((0, 9), dtype=np.float)

        # make sure this is a valid sparse MxN
        assert(pre.shape[0] / self.M == post.shape[0] / self.N)

        # fill synapses
        for i in np.arange(pre.shape[0]):
            i_post = np.empty((0, 9), dtype=np.float)
            m = np.floor(i / self.M).astype(np.int)

            for n in np.arange(self.N):
                to = np.zeros(9)
                to[1] = pre[i]
                to[2] = (m * self.N + n) + post[0]
                to[3] = np.random.uniform(low=wrange[0], high=wrange[1])
                to[4] = lr
                to[5] = fibres
                i_post = np.vstack((i_post, to))
            synapses = np.vstack((synapses, i_post))

        return synapses

class P_t_1:
    def __init__(self, P=.25):
        self.P = P

    def synapses(self, pre, post, wrange, fibres, lr):
        ''' Compute P%xN synapses '''

        p = np.round(pre.shape[0] * self.P).astype(np.int)
        synapses = np.empty((0, 9), dtype=np.float)

        for i in np.arange(post.shape[0]):
            i_syn = np.zeros((p, 9))
            i_syn[:,1] = np.random.choice(pre, size=p, replace=False)
            i_syn[:,2] = post[i]
            i_syn[:,3] = np.random.uniform(low=wrange[0], high=wrange[1], size=p)
            i_syn[:,4] = lr
            i_syn[:,5] = fibres
            synapses = np.vstack((synapses, i_syn))

        return synapses

class Full:
    def __init__(self):
        pass

    def synapses(self, pre, post, wrange, fibres, lr):
        ''' Compute full synapses '''

        synapses = np.zeros((pre.shape[0] * post.shape[0], 9), dtype=np.float)
        synapses[:,1] = np.matlib.repmat(np.arange(np.min(pre), np.max(pre) + 1).T, 1, int(synapses.shape[0] / pre.shape[0]))
        synapses[:,2] = np.repeat(np.arange(np.min(post), np.max(post) + 1), pre.shape[0])
        synapses[:,3] = np.random.uniform(low=wrange[0], high=wrange[1], size=int(pre.shape[0] * post.shape[0]))
        synapses[:,4] = lr
        synapses[:,5] = fibres

        return synapses

class One_t_One:
    def __init__(self):
        pass

    def synapses(self, pre, post, wrange, fibres, lr):
        ''' Compute 1:1 synapses '''

        synapses = np.zeros((pre.shape[0], 9), dtype=np.float)
        synapses[:,1] = pre
        synapses[:,2] = post
        synapses[:,3] = np.random.uniform(low=wrange[0], high=wrange[1], size=pre.shape[0])
        synapses[:,4] = lr
        synapses[:,5] = fibres

        return synapses
