% @Description: Compute evoked TFR of conditions for subject.

function subj_source_beta_bf(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % redefine trials and shift to 2^7 offset trigger to get at
    % between-trials beta
    cfg = [];
    cfg.offset = helper_get_beta_offsets(data.trialinfo, 400);
    data = ft_redefinetrial(cfg, data);
    
    % single-trial time-resolved power 1-7 Hz
    fprintf('\n*** Computing single-trial beta power ***\n');
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'fourier';
    cfg.taper = 'dpss';
    cfg.foi = 20;
    cfg.toi = -0.5:0.05:1.2; % note: -0.5-0 includes response artifacts but there's no way around that
    cfg.t_ftimwin = 0.5;
    cfg.tapsmofrq = 1; % this gives us a beta-band for 19-21Hz as per Bogaerts et al. (2020)
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
    
    for k = 1:size(conds, 1)
        cfg = [];
        cfg.trials = conds{k}.indices;
        cfg.avgoverrpt = 'yes';
        cfg.latency = [0 0.5];
        cfg.avgovertime = 'yes';
        sources{k} = ft_selectdata(cfg, source_pow);
        sources{k} = rmfield(sources{k}, 'cfg');
    end
    
    % save
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'subj_source_beta_bf.mat'), 'sources', 'conds', 'condslabels');
end