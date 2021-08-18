% @Description: Compute between-trial beta beamformer.

function subj_source_beta_bf_btwn(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % redefine trials and shift to 2^7 offset trigger to get at
    % between-trials beta
    % note: ft_redefinetrial could not be used here because none of the
    % options really do what we need. instead, i wrote a very hacky
    % work-around to re-cut and re-centre the data manually.
    %offsets = helper_get_beta_offsets(data.trialinfo, 400);
    %
    %for i = 1:size(offsets, 1)
    %    trl = data.trial{i};
    %    data.trial{i} = trl(:, offsets(i):end);
    %    data.time{i} = -0.5:(1/400):((size(data.trial{i}, 2) / 400) - 0.5 - (1/400));
    %end
    
    cfg = [];
    cfg.offset = -helper_get_beta_offsets(data.trialinfo, data.fsample);
    data = ft_redefinetrial(cfg, data);
    
    % single-trial time-resolved power 17-23 Hz
    fprintf('\n*** Computing single-trial beta power ***\n');
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'fourier';
    cfg.taper = 'dpss';
    cfg.foi = 20;
    cfg.toi = 0:0.05:0.9; % note: -0.25-0 includes response artifacts but there's no way around that
    cfg.t_ftimwin = 0.5;
    cfg.tapsmofrq = 3; % this gives us a beta-band for 18-24Hz which is slightly more inclusive than Bogaerts et al. (2020)
    
    
    if subject.ppn == 10
        % hacky work-around to fix one participant's data (the trigger
        % fiasco that is referenced a couple of times through-out the code
        % again)
        
        timing = [cellfun(@max, data.time)]';
        timing_on = find(timing > 1.4);
        cfg.trials = [timing_on];
    end
    
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
    %fprintf('\n*** Regressing out linear trend ***\n');
    %
    %cfg = [];
    %cfg.confound = helper_get_linear_confound();
    %cfg.confound = cfg.confound(trialinds,:);
    %source_pow = ft_regressconfound(cfg, source_pow);
    
    % regress out movement
    %fprintf('\n*** Regressing out movement ***\n');
    %
    %load(fullfile(subject.out, 'regressor-movement.mat'), 'cc_dm');
    %
    %cfg = [];
    %cfg.confound = [cc_dm ones(size(cc_dm, 1), 1)];
    %
    %if subject.ppn == 10
    %    % again, the classic work-around
    %    cfg.confound = cfg.confound([timing_on],:);
    %end
    %
    %cfg.reject = [1:6];
    %source_pow = ft_regressconfound(cfg, source_pow);
    
    % regress out confounds
    fprintf('\n*** Regressing out confounds ***\n');
    
    load(fullfile(subject.out, 'regressor-movement.mat'), 'cc_dm');
    
    con_pw = helper_get_linear_confound();
    con_pw = con_pw(trialinds,:);
    con_mv = [cc_dm ones(size(cc_dm, 1), 1)];
    
    if subject.ppn == 10
        % again, the classic work-around
        con_mv = con_mv([timing_on],:);
    end
    
    cfg = [];
    cfg.confound = cat(2, con_pw, con_mv);
    cfg.reject = [1:9];
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
    conds = helper_partition_trials(freq, conds);
    condslabels = {"L1P1", "L1P3", "L2P2", "L2P3"};
    
    sources = {};
    
    for k = 1:size(conds, 2)
        cfg = [];
        cfg.trials = conds{k}.indices;
        cfg.avgoverrpt = 'yes';
        cfg.latency = [0.5 0.8];
        cfg.avgovertime = 'yes';
        sources{k} = ft_selectdata(cfg, source_pow);
        sources{k} = rmfield(sources{k}, 'cfg');
    end
    
    % save
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'subj_source_beta_bf_btwn.mat'), 'sources', 'conds', 'condslabels');
end