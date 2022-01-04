% @Description: Compute beta ROI power.

function subj_source_beta_ROI(subject)
    % load data
    fprintf('\n*** Loading data ***\n');
    
    data = helper_clean_data(subject);
    
    % redefine trials and shift to 2^7 offset trigger to get at
    % between-trials beta
    % note: ft_redefinetrial could not be used here because none of the
    % options really do what we need. instead, i wrote a very hacky
    % work-around to re-cut and re-centre the data manually.    
    cfg = [];
    cfg.offset = -floor((data.trialinfo(:,5) + 300) / 1000 * data.fsample);
    data = ft_redefinetrial(cfg, data);
    
    
    % single-trial time-resolved power 17-23Hz
    fprintf('\n*** Computing single-trial theta power ***\n');
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'fourier';
    cfg.taper = 'dpss';
    cfg.foi = 20;
    cfg.toi = -0.5:0.05:0.9;
    cfg.t_ftimwin = 0.25;
    cfg.tapsmofrq = 4;
    
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
    
    % right SMG; right MTG; right MFG; right pars triangularis
    roi = [6218; 5676; 6416; 6317];
    leadfield.pos = leadfield.pos(roi,:);
    leadfield.leadfield = leadfield.leadfield(roi);
    leadfield.inside = true(numel(roi), 1);
    
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
    
    % average
    fprintf('\n*** Averaging ***\n');
    
    cfg = [];
    cfg.latency = [0.3 0.4];
    cfg.avgovertime = 'yes';
    source_pow_early = ft_selectdata(cfg, source_pow);
    source_pow_early.trialinfo = freq.trialinfo;
    
    cfg.latency = [0.4 0.6];
    source_pow_late = ft_selectdata(cfg, source_pow);
    source_pow_late.trialinfo = freq.trialinfo;
    
    % save
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'subj_source_beta_roi.mat'), 'source_pow_early', 'source_pow_late');
end