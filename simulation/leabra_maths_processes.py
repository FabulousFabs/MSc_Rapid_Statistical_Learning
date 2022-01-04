'''
Process utilities
'''

import numpy as np

def PoissonHomogenous(r, T=1, dt=1e-3):
    '''
    draw spikes from homogenous poisson distribution
    '''

    b = T / dt
    return np.clip(np.random.poisson(r, b), a_min=0, a_max=1)

def PoissonInhomogenous(r, T=1, dt=1e-3):
    '''
    draw spikes from inhomogenous poisson distribution
    '''

    t = np.arange(dt, T, dt)
    rb = .5 * (r(t) + r(t + dt))
    pb = 1 - np.exp(-rb * dt * 1e-3)
    s = np.random.uniform(size=t.shape[0])
    return np.array(pb >= s).astype(np.int)
