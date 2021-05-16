'''
Model class for hippocampus as per

    Schapiro, A.C., Turk-Browne, N.B., Botvinick, M.M., & Norman, K.A. (2017). Complementary learning systems within the hippocampus: A neural network modelling approach to reconciling episodic memory with statistical learning. Philosophical Transactions of the Royal Society B: Biological Sciences, 372, e20160049. DOI: http://dx.doi.org/10.1098/rstb.2016.0049

'''

import numpy as np
import numpy.matlib
import leabra_neurons as neurons
import leabra_connectivity as connectivity
import leabra_solvers as solvers

class Model:
    def __init__(self, load_model=None,
                       input_shape=(20, 472),
                       DG_shape=(1, 400),
                       CA3_shape=(1, 80),
                       CA1_shape=(1, 100),
                       solver=solvers.Heuns,
                       verbose=False,
                       progress=True):
        ''' Build our hippocampal model '''

        # logging state
        self.verbose = verbose
        self.progress = progress

        # solver
        self.solver = solver

        # neuron class for parameters and static functions
        self.neuron = neurons.Neuron()

        # learning rate for hebb & ed
        self.l_mix = [1.0, 0.001]

        # preamble to make sure our dt and theta cycle match up
        self.theta = 4 # Hz
        self.equilibrium_n = 30 # times dt
        self.dt = (1000 / self.theta) / (self.equilibrium_n * 3) # ms

        # preamble for our cycles
        self.TT = 0
        self.TP = 1
        self.P = 2
        self.cycles = np.array([self.TT, self.TP, self.P])

        # size and region initialisation
        self.log('*** Initialising regions. ***')
        CH_size = input_shape[0] * input_shape[1]
        EC_size = input_shape[0] * input_shape[1]
        DG_size = DG_shape[0] * DG_shape[1]
        CA3_size = CA3_shape[0] * CA3_shape[1]
        CA1_size = CA1_shape[0] * CA1_shape[1]
        regions = np.array([CH_size, EC_size, DG_size, CA3_size, CA1_size, EC_size])
        self.CH, self.EC, self.DG, self.CA3, self.CA1, self.EC_out = np.arange(len(regions))
        self.regions = np.array([[self.CH, 0.0],      # region, g_i
                                 [self.EC, 1.5],
                                 [self.DG, 3.3],
                                 [self.CA3, 2.1],
                                 [self.CA1, 2.1],
                                 [self.EC_out, 1.5]])

        if load_model is None:
            self.log('*** Running with mode load_model=None. ***')

            # neuron initialisation
            self.log('*** Initialising neurons. ***')
            M, N = (np.sum(regions), self.neuron.vectorised.shape[0])
            self.neurons = np.matlib.repmat(self.neuron.vectorised, M, 1)
            identities = np.array([])
            for i in np.arange(regions.shape[0]): identities = np.append(identities, np.ones(regions[i]) * i)
            self.neurons[:,0] = identities[:]
            for i in np.arange(regions.shape[0]): self.neurons[self.structure(i), 6] = self.neuron.fb * np.mean(self.neurons[self.structure(i), 6])

            # setup synapses
            self.log('*** Initialising synapses. ***')
            self.synapses = np.empty((0, 9), dtype=np.float)

            connections = [[0, self.CH, self.EC, (0.25, 0.75), (1, 1), connectivity.One_t_One(), 0.0],          # CH -> EC_in
                           [1, self.EC, self.DG, (0.25, 0.75), (1, 1), connectivity.P_t_1(P=.25), 0.2],         # EC_in -> DG
                           [2, self.EC, self.CA3, (0.25, 0.75), (1, 1), connectivity.P_t_1(P=.25), 0.2],        # EC_in -> CA3
                           [3, self.DG, self.CA3, (0.89, 0.91), (1, 8), connectivity.P_t_1(P=.05), 0.0],        # DG -> CA3 (mossy fibres)
                           [4, self.CA3, self.CA3, (0.25, 0.75), (1, 1), connectivity.Full(), 0.2],             # CA3 -> CA3
                           [5, self.CA3, self.CA1, (0.25, 0.75), (1, 1), connectivity.Full(), 0.05],            # CA3 -> CA1 (Schaffer collaterals)
                           [6, self.EC, self.CA1, (0.25, 0.75), (3, 1), connectivity.Full(), 0.02],             # EC_in -> CA1
                           [7, self.CA1, self.EC_out, (0.25, 0.75), (1, 1), connectivity.Full(), 0.02],         # CA1 -> EC_out
                           [8, self.EC_out, self.CA1, (0.25, 0.75), (1, 1), connectivity.Full(), 0.02],         # EC_out -> CA1
                           [9, self.EC_out, self.EC, (0.49, 0.51), (2, .5), connectivity.One_t_One(), 0.0],     # EC_out -> EC_in
                           [10, self.EC, self.EC_out, (0.49, 0.51), (1, 1), connectivity.One_t_One(), 0.0]]     # EC_in -> EC_out

            for planned in connections:
                self.log('\t...computing ' + str(planned[1]) + ' -> ' + str(planned[2]) + '.')

                constructor = planned[5]
                fibres = planned[0]
                pre = self.structure(planned[1])
                post = self.structure(planned[2])
                wrange = planned[3]
                lr = planned[6]

                synapses = constructor.synapses(pre, post, wrange, fibres, lr)
                synapses[:,6] = planned[1]
                synapses[:,7] = planned[2]

                self.synapses = np.vstack((self.synapses, synapses))

            self.synapses[:,0] = np.arange(self.synapses.shape[0]) # indices
            self.synapses[:,8] = 1 # clamp flag

            # scale synapses
            self.log('*** Scaling synapses. ***')

            scaled = []

            for planned in connections:
                self.log('\t...computing scaling for ' + str(planned[1]) + ' -> ' + str(planned[2]) + '.')

                scaling = planned[4]

                # put weights in scaled temporary container
                fibres = planned[0]
                scaled.append(np.copy(self.synapses[self.fibres(fibres),3]))

                # scale absolute
                scaled[-1] = scaled[-1] * scaling[0]

                # scale relative
                post = planned[2]

                all_conns = self.synapses[self.synapses_to(post)]
                avg_w = np.mean(all_conns[:,3])
                fibres_rel = np.mean(self.synapses[self.fibres(fibres),3] / avg_w)
                scaled[-1] = scaled[-1] * (scaling[1] * fibres_rel)

            for i in np.arange(len(scaled)):
                self.synapses[self.fibres(i),3] = scaled[i]

            self.log('*** Model built. ***')
        else:
            self.log('*** Loading model. ***')

            with open(load_model, 'rb') as f:
                self.neurons = np.load(f)
                self.synapses = np.load(f)

            self.log('*** Loading complete. ***')

    def save(self, to=None):
        if to is None:
            to = './models/' + str(np.datetime('now'))

        self.log('*** Saving model. ***')

        with open(to, 'wb') as f:
            np.save(f, self.neurons)
            np.save(f, self.synapses)

        self.log('*** Saving complete. ***')

    def log(self, msg):
        if self.verbose is True:
            print(msg)

    def structure(self, n_structure):
        ''' Quick access to all neuron indices of n_structure '''

        return np.where(self.neurons[:,0].astype(np.int) == int(n_structure))[0]

    def not_structure(self, n_structure):
        ''' Quick access to all neuron indices not of n_structure '''

        return np.where(self.neurons[:,0].astype(np.int) != int(n_structure))[0]

    def synapses_to(self, n_structure):
        ''' Quick access to all synapses going to n_structure '''

        return np.where(self.synapses[:,7].astype(np.int) == int(n_structure))[0]

    def fibres(self, n_fibres):
        ''' Quick access to all synapses part of n_fibres '''

        return np.where(self.synapses[:,5].astype(np.int) == int(n_fibres))[0]

    def simulate(self, source=None, to=None, reset=True):
        ''' Run a simulation given our input stimulus '''

        cycles_settled = np.zeros((3, self.neurons.shape[0]))

        for cycle in self.cycles:
            self.start_cycle(cycle)

            for i in np.arange(self.equilibrium_n):
                # get t
                t = (cycle * self.equilibrium_n + i) * self.dt

                # progress (if verbose)
                if self.progress is True:
                    progress = t / (1000 / self.theta)
                    print('[\t\t\t\t\t]', end='\r')
                    print('[' + ''.join(['-' for i in range(int(progress * 40))]), end='\r')
                    print('\t\t{:2.2f}%.'.format(np.round(progress*100, 2)), end='\r')

                # who spiked? reset
                spiked = np.where(self.neurons[:,4] >= self.neuron.theta)[0]
                if spiked.shape[0] > 0: self.neurons[spiked,4] = self.neuron.V_m_r
                #print(spiked.shape)
                if spiked.shape[0] > 0:
                    for region in self.regions:
                        neurons = self.structure(region[0])
                        spiked_neurons = np.intersect1d(neurons, spiked)
                        print(str(region[0]) + '=' + str(spiked_neurons.shape))

                # averages
                self.neurons[:,7:] = self.neuron.avg(self.neurons[:,7], self.neurons[:,8], self.neurons[:,9], self.neurons[:,10], self.neurons[:,5], self.dt)

                # reset all input currents
                #other = self.not_structure(to)
                #self.neurons[other,1] = self.neuron.g_e
                #self.neurons[:,2] = self.neuron.g_i
                #self.neurons[:,3] = self.neuron.g_l

                # post-groupings, compute g_e_t
                if spiked.shape[0] > 0:
                    cross, actsynind, spikeind = np.intersect1d(self.synapses[:,1], spiked, return_indices=True)
                    receiving_neurons = self.synapses[actsynind,2]
                    unique_receiving_neurons, unique_receiving_inverse = np.unique(receiving_neurons, return_inverse=True)

                    for i in np.arange(unique_receiving_neurons.shape[0]):
                        target = unique_receiving_neurons[i].astype(np.int)
                        indx = unique_receiving_inverse[np.where(unique_receiving_inverse == i)[0]]
                        spikers = cross[indx].astype(np.int)

                        x = self.neurons[spikers,5]
                        w = self.synapses[actsynind[indx],3] * self.synapses[actsynind[indx],8]

                        self.neurons[target,1] = self.neuron.g_e_t(x, w)

                # compute g_i_t (layer-wise)
                for region in self.regions:
                    neurons = self.structure(region[0])

                    g_i = region[1]
                    avg_act = np.mean(self.neurons[neurons,5]) # N
                    #print(avg_act)
                    avg_net = np.mean(self.neurons[neurons,1]) # Y
                    #print(avg_net)
                    self.neurons[neurons,2] = self.neuron.g_i_t(g_i, self.neurons[neurons,6], avg_act, avg_net)
                    #print(self.neurons[neurons,2])

                # setup source currents
                ins = self.structure(to)
                self.neurons[ins,1] = 1

                # integration
                for region in self.regions:
                    neurons = self.structure(region[0])
                    avg_V = np.mean(self.neurons[neurons,4])
                    avg_E = np.mean(self.neurons[neurons,1])
                    avg_I = np.mean(self.neurons[neurons,2])
                    #print('Avg. V: ' + str(avg_V) + ' in ' + str(region[0]))
                    #print('Avg. E: ' + str(avg_E) + ' in ' + str(region[0]))
                    #print('Avg. I: ' + str(avg_V) + ' in ' + str(region[0]))
                #self.neurons[:,4] = np.maximum(self.neuron.V_m_min, self.solver(self.neurons[:,4], t, self.dt, self.neuron.dVdt, g_e=self.neurons[:,1], g_i=self.neurons[:,2]))
                #self.neurons[:,4] = self.neurons[:,4] + self.dt * self.neuron.dVdt(self.neurons[:,4], t, {'g_e': self.neurons[:,1], 'g_i': self.neurons[:,2]})
                self.neurons[:,4] = self.neurons[:,4] + self.dt * self.neuron.dVdt(self.neurons[:,4], t, {'g_e': self.neurons[:,1], 'g_i': self.neurons[:,2]})
                for region in self.regions:
                    neurons = self.structure(region[0])
                    avg_V = np.mean(self.neurons[neurons,4])
                    #print('Avg. V (post): ' + str(avg_V) + ' in ' + str(region[0]))

                # activations
                #self.neurons[:,5] = self.neuron.y_i(self.neurons[:,4])
                #self.neurons[:,5] = self.neuron.y_i(self.neurons[:,1], self.neurons[:,2])
                #self.neurons[:,5] = self.solver(self.neurons[:,5], t, self.dt, self.neuron.dydt, g_e=self.neurons[:,1], g_i=self.neurons[:,2])
                #self.neurons[:,6] = self.solver(self.neurons[:,6], t, 1.0, self.neuron.fb_t2, Y=self.neurons[:,5])
                act = np.copy(self.neurons[:,5])
                #self.neurons[:,5] = act + self.dt * self.neuron.dydt(act, t, {'g_e': self.neurons[:,1], 'g_i': self.neurons[:,2]})
                self.neurons[:,5] = self.neuron.dydt(self.neurons[:,10], t, {'g_e': self.neurons[:,1], 'g_i': self.neurons[:,2]})
                self.neurons[:,6] = self.neuron.fb_t(self.neurons[:,6], self.neurons[:,10])
                for region in self.regions:
                    neurons = self.structure(region[0])
                    avg_V = np.mean(self.neurons[neurons,4])
                    avg_Y = np.mean(self.neurons[neurons,5])
                    avg_E = np.mean(self.neurons[neurons,1])
                    avg_E_thr = np.mean(self.neuron.g_e_thr(self.neurons[neurons,2]))
                    avg_E_E_thr = np.mean(self.neurons[neurons,1] - self.neuron.g_e_thr(self.neurons[neurons,2]))
                    #print(str(region[0]) + '=Avg. V (post): ' + str(avg_V))
                    #print(str(region[0]) + '=Avg. Y (post): ' + str(avg_Y))
                    #print(str(region[0]) + '=Avg. E_thr (post): ' + str(avg_E_thr))
                    print(str(region[0]) + '=Avg. E-E_thr (post): ' + str(avg_E_E_thr))


            cycles_settled[cycle,:] = self.neurons[:,5]

            self.end_cycle(cycle)

    def start_cycle(self, cycle):
        ''' Start the cycle '''

        if cycle == self.TT:
            self.prep_TT()
        elif cycle == self.TP:
            self.prep_TP()
        elif cycle == self.P:
            self.prep_P()

    def end_cycle(self, cycle):
        '''
        Unclamps all fibres.
        '''

        self.synapses[:,8] = 1

    def prep_TT(self):
        '''
        Clamps fibres such that:

                1   =   EC_in -> CA1        (fibres 6)
                0   =   CA3 -> CA1          (fibres 5)
                0   =   EC_in -> EC_out     (fibres 10)
        '''

        self.synapses[self.fibres(6),8] = 1
        self.synapses[self.fibres(5),8] = 0
        self.synapses[self.fibres(10),8] = 0

    def prep_TP(self):
        '''
        Clamps fibres such that:

                0   =   EC_in -> CA1        (fibres 6)
                1   =   CA3 -> CA1          (fibres 5)
                0   =   EC_in -> EC_out     (fibres 10)
        '''

        self.synapses[self.fibres(6),8] = 0
        self.synapses[self.fibres(5),8] = 1
        self.synapses[self.fibres(10),8] = 0

    def prep_P(self):
        '''
        Clamps fibres such that:

                1   =   EC_in -> CA1        (fibres 6)
                0   =   CA3 -> CA1          (fibres 5)
                1   =   EC_in -> EC_out     (fibres 10)
        '''

        self.synapses[self.fibres(6),8] = 1
        self.synapses[self.fibres(5),8] = 0
        self.synapses[self.fibres(10),8] = 1
