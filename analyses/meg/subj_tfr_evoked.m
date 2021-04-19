% @Description: Compute TFR of trials over time for subject.

function [freqs, conds] = subj_tfr_evoked(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % channel repair
    fprintf ('\n*** Neighbours (skipping channel repair) ***\n');
    cfg = [];
    cfg.method = 'template';
    cfg.template = 'ctf275_neighb.mat';
    neighbours = ft_prepare_neighbours(cfg);
    
    % comment:
    % this is the place where we would want to do
    % channel repair as Eelke does it as well but
    % I'm afraid we just don't have enough of the
    % data set to think about that yet
    % @todo: channel repair
    
    % baseline demean
    fprintf('\n*** Baseline correction ***\n');
    
    cfg = [];
    cfg.demean = 'yes';
    cfg.baselinewindow = [-0.5 0];
    data = ft_preprocessing(cfg, data);
    
    % convert to planar
    fprintf('\n*** Converting to planar ***\n');
    
    cfg = [];
    cfg.neighbours = neighbours;
    cfg.planarmethod = 'sincos';
    data = ft_megplanar(cfg, data);
    
    % conditioning :-)
    fprintf('\n*** Partitioning trials ***\n');
    
    conds = [1 3 5 6];
    conds = helper_partition_trials(data, conds);
    condslabels = {"L1P1", "L1P3", "L2P2", "L2P3"};
    
    % planar ERFs
    fprintf('\n*** Computing ERFs ***\n');
    
    freqs = {};
     
    for k=1:size(conds, 2)
        cfg = [];
        cfg.trials = conds{k}.indices;
        tl = ft_timelockanalysis(cfg, data);
        
        cfg = [];
        cfg.pad = 10;
        cfg.method = 'mtmconvol';
        cfg.toi = -0.5:0.05:1.0;
        cfg.taper = 'hanning';
        cfg.foi = 1:30;
        cfg.t_ftimwin = ones(size(cfg.foi)) * 0.5;
        
        freqs{k} = ft_freqanalysis(cfg, tl);
        freqs{k} = ft_combineplanar([], freqs{k});
        freqs{k} = rmfield(freqs{k}, 'cfg');
    end
    
    save(fullfile(subject.out, 'sensor_evoked_tfr.mat'), 'freqs', 'conds', 'condslabels');
end