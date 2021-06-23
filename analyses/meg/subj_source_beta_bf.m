% @Description: Compute beta beamformer.

function subj_source_beta_bf(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % single-trial time-resolved power 17-23 Hz
    fprintf('\n*** Computing single-trial theta power ***\n');
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'fourier';
    cfg.taper = 'dpss';
    cfg.foi = 20;
    cfg.toi = -0.5:0.05:1;
    cfg.t_ftimwin = 0.5;
    cfg.tapsmofrq = 3;
    freq = ft_freqanalysis(cfg, data);
    trialinds = freq.trialinfo(:,8);
    
    % load leadfields + head model
    fprintf('\n*** Loading leadfields + headmodel. ***\n');
    
    load(fullfile(subject.out, 'geom-leadfield-mni-8mm-megchans.mat'), 'headmodel', 'leadfield');
    
    % source analysis to compute DICS spatial filters
    fprintf('\n*** Computing DICS spatial filters ***\n');
    
    cfg = [];
    cfg.method = 'dics';
    cfg.grid = leadfield;
    cfg.headmodel = headmodel;
    cfg.keeptrials = 'yes';
    cfg.dics.lambda = '10%';
    cfg.dics.projectnoise = 'no';
    cfg.dics.keepfilter = 'yes';
    cfg.dics.fixedori = 'yes';
    cfg.dics.realfilter = 'yes';
    source = ft_sourceanalysis(cfg, freq);
    
    % apply filters to fourier spectra & compute time-resolved power
    source_pow = helper_compute_single_trial_power(source, freq);
    source_pow.dimord = 'pos_rpt_time';
    
    % regress out linear trend
    fprintf('\n*** Regressing out linear trend ***\n');
    
    cfg = [];
    cfg.confound = helper_get_linear_confound();
    cfg.confound = cfg.confound(trialinds,:);
    source_pow = ft_regressconfound(cfg, source_pow);
    
    % baseline correct individual trials using z-score as per eelke's code
    % see Spaak & de Lange (2020) or Grandchamp & Delorme (2011)
    fprintf('\n*** Correcting baselines ***\n');
    
    mu = mean(source_pow.pow, 3);
    sd = std(source_pow.pow, [], 3);
    source_pow.pow = (source_pow.pow - mu) ./ sd;
    
    % conditioning
    fprintf('\n*** Conditioning :-) ***\n');
    
    conds = [1 3 5 6];
    conds = helper_partition_trials(data, conds);
    condslabels = {"L1P1", "L1P3", "L2P2", "L2P3"};
    
    sources = {};
    
    for k = 1:size(conds, 2)
        cfg = [];
        cfg.trials = conds{k}.indices;
        cfg.avgoverrpt = 'yes';
        cfg.latency = [0.25 0.75];
        cfg.avgovertime = 'yes';
        sources{k} = ft_selectdata(cfg, source_pow);
        sources{k} = rmfield(sources{k}, 'cfg');
    end
    
    % save
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'subj_source_beta_bf.mat'), 'sources', 'conds', 'condslabels');
end