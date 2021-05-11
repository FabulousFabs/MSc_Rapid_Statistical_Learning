% @Description: Runs processing steps for all subjects.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';

% Select participant
subjects = helper_datainfo(rootdir);

for k = 2:size(subjects, 2)
    subject = subjects(k);
    
    fprintf('\n*** Processing data for k=%d, sub-%02d. *** \n', k, subject.ppn);
    
    subj_tfr_evoked(subject);
    subj_tfr(subject);
    subj_source_theta_bf(subject);
    subj_source_beta_bf(subject);
end

%% test data
subject = subjects(sid);

fprintf('\n*** Loading data ***\n');
    
data = helper_clean_data(subject);
   
%% test data 2
    % load leadfields + head model
    fprintf('\n*** Loading leadfields + headmodel. ***\n');
    
    load(fullfile(subject.out, 'geom-leadfield-mni-8mm-megchans.mat'), 'headmodel', 'leadfield');
    
    % single-trial time-resolved power 1-7 Hz
    fprintf('\n*** Computing single-trial theta power ***\n');
    
    cfg = [];
    cfg.method = 'mtmconvol';
    cfg.output = 'fourier';
    cfg.taper = 'dpss';
    cfg.foi = 4;
    cfg.toi = -0.5:0.05:1;
    cfg.t_ftimwin = 0.5;
    cfg.tapsmofrq = 3; % 1-7Hz
    freq = ft_freqanalysis(cfg, data);
    trialinds = freq.trialinfo(:,8);
    
    %% test data 3 
    % source analysis to compute DICS spatial filters
    fprintf('\n*** Computing DICS spatial filters ***\n');
    
    cfg = [];
    cfg.method = 'dics';
    cfg.grid = leadfield;
    %cfg.sourcemodel = leadfield;
    cfg.headmodel = headmodel;
    cfg.keeptrials = 'yes';
    cfg.dics.lambda = '10%';
    cfg.dics.projectnoise = 'no';
    cfg.dics.keepfilter = 'yes';
    cfg.dics.fixedori = 'yes';
    cfg.dics.realfilter = 'yes';
    source = ft_sourceanalysis(cfg, freq);
    
    %%
    % apply filters to fourier spectra & compute time-resolved power
    source_pow = helper_compute_single_trial_power(source, freq);
    source_pow.dimord = 'pos_rpt_time';
    
    %% test data 4
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
        cfg.latency = [0 0.5];
        cfg.avgovertime = 'yes';
        sources{k} = ft_selectdata(cfg, source_pow);
        sources{k} = rmfield(sources{k}, 'cfg');
    end
    
    %% plot
    [~, ftpath] = ft_version();
    load(fullfile(ftpath, 'template', 'sourcemodel', 'standard_sourcemodel3d8mm.mat'), 'sourcemodel');
    template_grid = sourcemodel;
    clear sourcemodel;
    
    %%
    s = {};
    for k = 1:numel(sources)
        s{k}.inside = template_grid.inside;
        s{k}.pos = template_grid.pos;
        s{k}.dim = template_grid.dim;
        
        tmp = sources{k}.pow;
        s{k}.pow = nan(size(template_grid.pos,1), size(tmp, 2), size(tmp, 3));
        s{k}.pow(template_grid.inside,:,:) = tmp;
        %s{k}.pow(template_grid.inside,:,:) = tmp(template_grid.inside);
    end
    
    %%
    mri = ft_read_mri(fullfile(rootdir, 'processed', 'combined', 'average305_t1_tal_lin.nii'));
    mri.coordsys = 'mni';
    
    %%
    source_diff = {};
    cfg = [];
    cfg.parameter = 'avg.pow';
    %cfg.operation = '(x1 ./ x2) - 1';
    cfg.operation = '(x1 - x2)';
    source_diff{1} = ft_math(cfg, s{1}, s{2});
    source_diff{2} = ft_math(cfg, s{3}, s{4});
    source_diff{3} = ft_math(cfg, s{1}, s{3});
    source_diff{4} = ft_math(cfg, s{2}, s{4});
    source_diff{5} = ft_math(cfg, source_diff{1}, source_diff{2});
    
    %%
    source_diff_int = {};
    cfg = [];
    cfg.parameter = 'pow';
    cfg.interpmethod = 'nearest';
    source_diff_int{1} = ft_sourceinterpolate(cfg, source_diff{1}, mri);
    source_diff_int{2} = ft_sourceinterpolate(cfg, source_diff{2}, mri);
    source_diff_int{3} = ft_sourceinterpolate(cfg, source_diff{3}, mri);
    source_diff_int{4} = ft_sourceinterpolate(cfg, source_diff{4}, mri);
    source_diff_int{5} = ft_sourceinterpolate(cfg, source_diff{5}, mri);
    
    %%
    cfg = [];
    cfg.atlas = fullfile(ftpath, 'template', 'atlas', 'aal', 'ROI_MNI_V4.nii');
    cfg.method = 'slice';
    cfg.funparameter = 'pow';
    cfg.maskparameter = cfg.funparameter;
    cfg.funcolorlim = [-0.5 0.6];
    cfg.opacitylim = [-0.5 0.6];
    cfg.opacitymap = 'rampup';
    ft_sourceplot(cfg, source_diff_int{1});
    ft_sourceplot(cfg, source_diff_int{2});
    ft_sourceplot(cfg, source_diff_int{3});
    ft_sourceplot(cfg, source_diff_int{4});
    ft_sourceplot(cfg, source_diff_int{5});