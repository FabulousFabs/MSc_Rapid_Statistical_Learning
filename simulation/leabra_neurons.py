'''
Neuron model as per

    Ketz, N., Morkonda, S.G., & O'Reilly, R.C. (2013). Theta coordinated error-driven learning in the hippocampus. PLoS Computational Biology, 9, e1003067. DOI: http://dx.doi.org/10.1371/journal.pcbi.1003067
    Schapiro, A.C., Turk-Browne, N.B., Botvinick, M.M., & Norman, K.A. (2017). Complementary learning systems within the hippocampus: A neural network modelling approach to reconciling episodic memory with statistical learning. Philosophical Transactions of the Royal Society B: Biological Sciences, 372, e20160049. DOI: http://dx.doi.org/10.1098/rstb.2016.0049
'''

import numpy as np

class Neuron:
    def __init__(self):
        self.g_e = 0.0                  # Excitatory input current
        self.g_i = 0.0                  # Inhibitory input current
        self.g_l = 1.0                  # Leak current
        self.g_bar_e = 1.0              # Max excitatory conductance
        self.g_bar_i = 1.0              # Max inhibitory conductance
        self.g_bar_l = 0.1              # Max leak conductance
        self.e_e = 1.0                  # Excitatory reversal potential
        self.e_i = 0.25                 # Inhibitory reversal potential
        self.e_l = 0.3                  # Leak reversal potential
        self.gamma = 100.0              # Activation function gain factor
        self.theta = 0.5                # Activation function firing threshold
        self.V_m_init = 0.4             # Initialise V_m to this
        self.V_m_r = 0.3                # Reset V_m to this after spike
        self.V_m_min = 0.0              # Minimal V_m
        self.V_m_max = 2.0              # Maximal V_m
        self.tau = 3.3                  # dVdt time constant
        self.gi = 2.0                   # inhibitory gain
        self.fb_dt = 0.7                # dt for fb inhibition (for fb_tau = 1.4)
        self.fb = 0.5                   # gain for feedback inhibition
        self.ff0 = 0.1                  # threshold for feedforward inhibition
        self.ff = 1.0                   # gain for feedforward inhibition
        self.ss_dt = 0.5                # time step for super-short average
        self.s_dt = 0.5                 # time step for short average
        self.m_dt = 0.1                 # time step for medium average
        self.l_dt = 0.1                 # time step for long average
        self.l_max = 1.5                # max value of avg_l
        self.l_min = 0.1                # min value of avg_l


    @property
    def vectorised(self):
        ''' Returns a vectorised version of relevant values '''
        ''' 0:  region,
            1:  g_e,
            2:  g_i,
            3:  g_l,
            4:  V,
            5:  y,
            6:  fbi,
            7:  avg_ss,
            8:  avg_s,
            9:  avg_m,
            10: avg_l,
            11: avg_eff '''

        return np.array([0.0,                           # region
                         self.g_e,                      # g_e
                         self.g_i,                      # g_i
                         self.g_l,                      # g_l
                         self.V_m_init,                 # V
                         self.y_i(self.V_m_init),       # y
                         0.0,                           # fbi (initialise from outside as fb * avg_act_Layer)
                         self.y_i(self.V_m_init),       # avg_ss
                         self.y_i(self.V_m_init),       # avg_s
                         self.y_i(self.V_m_init),       # avg_m
                         self.l_min,                    # avg_l
                         self.y_i(self.V_m_init)])      # avg_eff

    def dVdt(self, V, t, kwargs):
        '''
        Membrane potential:

         dV_m(t)
        --------  =  tau * sum_c[  g_c(t) * g_c^bar * (E_c - V_m(t))  ]
           dt

                where:

                    g_c = [g_e = Excitatory input current,
                           g_i = Inhibitory current (FFFB),
                           g_l = Constant leak current]
        '''

        return self.tau * ((kwargs['g_e'] * self.g_bar_e * (self.e_e - V)) +
                           (kwargs['g_i'] * self.g_bar_i * (self.e_i - V)) +
                           (self.g_l * self.g_bar_l * (self.e_l - V)))

    def g_e_t(self, x, w):
        '''
        Excitatory input current:

                     1
        g_e_j(t)  =  - * sum_i[  x_i * w_ij  ]
                     n
        '''

        return 1 / x.shape[0] * np.sum(x * w)

    def g_e_thr(self, g_i):
        '''
        Amount of excitatory conductance required to hit threshold exactly. This
        is used for input spikes.

                        gc_i * (e_rev_i - theta) + gc_l * (e_rev_l - theta)
        g_e_thr  =  -----------------------------------------------------------
                                        (theta - e_rev.e)
        '''

        return (g_i * (self.e_i - self.theta) + self.g_bar_l * (self.e_l - self.theta)) / (self.theta - self.e_e)


#    def g_i_t(self, fbi, avg_act):
#        '''
#        Inhibitory input current:
#
#        g_i_j(t)  =  g_i * (ffi + fbi)
#
#                where:
#
#                    g_i = constant inhibition gain
#
#                    ffi = ff * max(0, [avg_act - ff0])
#
#                    fbi = fbi + fb_dt * ([fb * avg_act] - fbi)
#        '''
#
#        ffi = self.ff * np.max(np.array([0, (avg_act - self.ff0)]))
#        fbi = fbi + self.fb_dt * (self.fb * avg_act - fbi)
#
#        return self.g_i * (ffi + fbi)

    def g_i_t(self, g_i, fbi, N, Y):
        return g_i * (self.ff_t(N) + self.fb_t(fbi, Y))

    def ff_t(self, N):
        return self.ff * (N - self.ff0)

    def fb_t(self, fbi, Y):
        return fbi + (self.fb_dt * (self.fb * Y - fbi))

    def fb_t2(self, fbi, t, kwargs):
        return (self.fb_dt * (self.fb * kwargs['Y'] - fbi))


    def avg(self, avg_ss, avg_s, avg_m, avg_l, y, dt):
        '''
        Updates the averages
        '''

        avg_ss = avg_ss + dt * (self.ss_dt * (y - avg_ss))
        avg_s = avg_s + dt * (self.s_dt * (avg_ss - avg_s))
        avg_m = avg_m + dt * (self.m_dt * (avg_s - avg_m))
        avg_l = avg_l + dt * (self.l_dt * (self.l_max - avg_m)) # avg_m > .2
        avg_l_s = avg_l + dt * (self.l_dt * (self.l_min - avg_m)) # avg_m <= .2
        if np.where(avg_m <= .2)[0].shape[0] > 0: avg_l[np.where(avg_m <= .2)[0]] = avg_l_s[np.where(avg_m <= .2)[0]] # fill in
        avg_eff = (avg_l - self.l_min) / (self.l_max - self.l_min)

        return np.array([avg_ss, avg_s, avg_m, avg_l, avg_eff]).T


#    def y_i(self, V):
#        '''
#        Activation function:
#                                    1
#        y_i(t)  =  ---------------------------------------
#                    1 + (gamma * [V_m(t) - theta]_+)^(-1)
#
#                where:
#
#                    gamma = 100 (gain factor)
#                    theta = g_e_thr
#        '''
#
#        return 1 / (1 + (self.gamma * (V - self.theta))**(-1))

    def dydt(self, Y, t, kwargs):
        return 1 / (1 + (self.gamma * (kwargs['g_e'] - self.g_e_thr(kwargs['g_i'])))**(-1))
