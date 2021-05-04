% @Description: Compute evoked TFR of conditions for subject.

function subj_tfr(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % neighbours
    fprintf('\n*** Computing neighbours (skipping repair) ***\n');
    
    cfg = [];
    cfg.method = 'template';
    cfg.template = 'ctf275_neighb.mat';
    neighbours = ft_prepare_neighbours(cfg);
    
    % channel repair is currently skipped
    % this is where we will want to implement that
    % once we have all the data
    
    % Convert to planar
    fprintf('\n*** Converting to planar ***\n');
    
    cfg = [];
    cfg.neighbours = neighbours;
    cfg.planarmethod = 'sincos';
    data = ft_megplanar(cfg, data);
    
    % mtmconvol
    fprintf('\n*** Computing mtmconvol ***\n');
    
    cfg = [];
    cfg.pad = 7; % the absolute maximum for our trials is technically 4.671s + 2.000s (pre+post) but that's ugly
    cfg.method = 'mtmconvol';
    cfg.toi = -0.5:0.05:1;
    cfg.keeptrials = 'yes';
    cfg.taper = 'hanning';
    cfg.foi = 1:30;
    cfg.t_ftimwin = ones(size(cfg.foi)) * 0.5;
    freq = ft_freqanalysis(cfg, data);
    
    % combine planar
    fprintf('\n*** Combining planar ***\n');
    
    freq = ft_combineplanar([], freq);
    
    % regress out linear trend
    fprintf('\n*** Regressing out linear trend ***\n');
    
    trialinds = freq.trialinfo(:,8);
    grad = freq.grad;
    cfg = [];
    cfg.confound = helper_get_linear_confound();
    cfg.confound = cfg.confound(trialinds,:);
    freq = ft_regressconfound(cfg, freq);
    freq.grad = grad;
    
    % individual baseline correction
    % of course, also using the z-score used by eelke
    % see Spaak & de Lange (2020) or Grandchamp & Delorme (2011)
    fprintf('\n*** Individual baseline correction ***\n');
    
    mu = mean(freq.powspctrm, 4);
    sd = std(freq.powspctrm, [], 4);
    freq.powspctrm = (freq.powspctrm - mu) ./ sd;
    
    % conditioning
    fprintf('\n*** Conditioning :-) ***\n');
    
    conds = [1 3 5 6];
    conds = helper_partition_trials(data, conds);
    condslabels = {"L1P1", "L1P3", "L2P2", "L2P3"};
    
    freqs = {};
    cfg = [];
    
    for k = 1:size(conds, 1)
        cfg.trials = conds{k}.indices;
        freqs{k} = ft_freqdescriptives(cfg, freq);
        freqs{k} = rmfield(freqs{k}, 'cfg');
    end
    
    % save 
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'subj_tfr.mat'), 'freqs', 'conds', 'condslabels');
end