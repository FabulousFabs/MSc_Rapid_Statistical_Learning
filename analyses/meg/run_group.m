% @Description: Runs all group-level analyses.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

% Select participant
subjects = helper_datainfo(rootdir);

%%
fprintf('\n*** Aggregating data across subjects ***\n');
    
    theta_allsources = {};
    theta1_allsources = {};
    theta2_allsources = {};
    theta_allconds = {};
    theta_condslabels = {};
    
    for k=1:numel(subjects)
        
        % make sure we include only data from participants where we made
        % the decision to include their data in analyses
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end
        
        load(fullfile(subjects(k).out, 'subj_source_theta_bf.mat'), 'sources', 'sources_early', 'sources_late', 'conds', 'condslabels');
        
        theta_allsources{k} = sources;
        theta_allconds{k} = conds;
        theta_condslabels = condslabels;
        
        theta1_allsources{k} = sources;
        theta2_allsources{k} = sources;
    end
    
    theta_allsources = cat(1, theta_allsources{:}); % subject x condition
    theta1_allsources = cat(1, theta1_allsources{:}); % subject x condition
    theta2_allsources = cat(1, theta2_allsources{:}); % subject x condition
    
    % translate coordinates
    fprintf('\n*** MNI translation. ***\n');
    
    load(sourcemodel_loc, 'sourcemodel');
    template_grid = sourcemodel;
    clear sourcemodel;
    
    for k = 1:numel(theta_allsources)
        theta_allsources{k}.inside = template_grid.inside;
        theta_allsources{k}.pos = template_grid.pos;
        theta_allsources{k}.dim = template_grid.dim;
        
        tmp = theta_allsources{k}.pow;
        theta_allsources{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        theta_allsources{k}.pow(template_grid.inside,:,:) = tmp;
        
        theta1_allsources{k}.inside = template_grid.inside;
        theta1_allsources{k}.pos = template_grid.pos;
        theta1_allsources{k}.dim = template_grid.dim;
        
        tmp = theta1_allsources{k}.pow;
        theta1_allsources{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        theta1_allsources{k}.pow(template_grid.inside,:,:) = tmp;
        
        theta2_allsources{k}.inside = template_grid.inside;
        theta2_allsources{k}.pos = template_grid.pos;
        theta2_allsources{k}.dim = template_grid.dim;
        
        tmp = theta2_allsources{k}.pow;
        theta2_allsources{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        theta2_allsources{k}.pow(template_grid.inside,:,:) = tmp;
    end
    
    % compute t-map
    fprintf('\n*** Computing t-maps. ***\n');
    
    cfg = [];
    cfg.parameter = 'pow';
    cfg.method = 'analytic';
    cfg.correctm = 'no';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.tail = 0;
    
    nobs = size(theta_allsources, 1);
    cfg.design = [
        ones(1, nobs)*1 ones(1, nobs)*2
        1:nobs 1:nobs
    ];
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    %%
    theta1_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, theta1_allsources{:,1}, theta_allsources{:,3});
    theta1_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, theta1_allsources{:,2}, theta_allsources{:,4});
    theta1_stat_l1p1_l1p3 = ft_sourcestatistics(cfg, theta1_allsources{:,1}, theta_allsources{:,2});
    theta1_stat_l2p2_l2p3 = ft_sourcestatistics(cfg, theta1_allsources{:,3}, theta_allsources{:,4});
    
    theta2_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, theta2_allsources{:,1}, theta2_allsources{:,3});
    theta2_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, theta2_allsources{:,2}, theta2_allsources{:,4});
    theta2_stat_l1p1_l1p3 = ft_sourcestatistics(cfg, theta2_allsources{:,1}, theta2_allsources{:,2});
    theta2_stat_l2p2_l2p3 = ft_sourcestatistics(cfg, theta2_allsources{:,3}, theta2_allsources{:,4});
    
    %%
    fprintf('\n*** Interpolating onto MNI. ***\n');
    
    mri = ft_read_mri(fullfile(rootdir, 'processed', 'combined', 'average305_t1_tal_lin.nii'));
    mri.coordsys = 'mni';
    
    cfg = [];
    cfg.parameter = 'stat';
    
    theta1_stat_l1p1_l2p2_interp = ft_sourceinterpolate(cfg, theta1_stat_l1p1_l2p2, mri);
    theta1_stat_l1p3_l2p3_interp = ft_sourceinterpolate(cfg, theta1_stat_l1p3_l2p3, mri);
    theta1_stat_l1p1_l1p3_interp = ft_sourceinterpolate(cfg, theta1_stat_l1p1_l1p3, mri);
    theta1_stat_l2p2_l2p3_interp = ft_sourceinterpolate(cfg, theta1_stat_l2p2_l2p3, mri);
    
    theta2_stat_l1p1_l2p2_interp = ft_sourceinterpolate(cfg, theta2_stat_l1p1_l2p2, mri);
    theta2_stat_l1p3_l2p3_interp = ft_sourceinterpolate(cfg, theta2_stat_l1p3_l2p3, mri);
    theta2_stat_l1p1_l1p3_interp = ft_sourceinterpolate(cfg, theta2_stat_l1p1_l1p3, mri);
    theta2_stat_l2p2_l2p3_interp = ft_sourceinterpolate(cfg, theta2_stat_l2p2_l2p3, mri);
    
    %%
    cfg = [];
    cfg.atlas = fullfile('/home', 'common', 'matlab', 'fieldtrip', 'template', 'atlas', 'aal', 'ROI_MNI_V4.nii');
    cfg.funparameter = 'stat';
    cfg.method = 'ortho';
    %cfg.roi = {'Hippocampus_L', 'Hippocampus_R'
    %cfg.roi = {'Hippocampus_L', 'Hippocampus_R', 'ParaHippocampal_L', 'ParaHippocampal_R', 'Frontal_Sup_L', 'Frontal_Sup_R'};
    %cfg.roi = {'Hippocampus_R', 'Frontal_Sup_L', 'Heschl_L', 'Temporal_Sup_L'};
    %cfg.roi = {'Hippocampus_R'};
    
    %cfg.location = [42.9 -30.5 -9.3];
    
    ft_sourceplot(cfg, theta2_stat_l2p2_l2p3_interp);
    %cfg.roi = {'Hippocampus_L', 'Hippocampus_R', 'ParaHippocampal_L', 'ParaHippocampal_R', 'Frontal_Sup_L', 'Frontal_Sup_R'};
    %cfg.roi = {'Hippocampus_R', 'Frontal_Sup_L', 'Heschl_L', 'Temporal_Sup_L'};
    %cfg.roi = {'Hippocampus_R'};
    
    %cfg.location = [42.9 -30.5 -9.3];
    
    
    %%
    
    theta_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, theta_allsources{:,1}, theta_allsources{:,3});
    theta_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, theta_allsources{:,2}, theta_allsources{:,4});
    
    ft_sourceplot(cfg, theta1_stat_l1p1_l2p2_interp);
    
    %%
    
    theta_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, theta_allsources{:,1}, theta_allsources{:,3});
    theta_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, theta_allsources{:,2}, theta_allsources{:,4});
    
    %%
    
    theta_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, theta_allsources{:,1}, theta_allsources{:,3});
    theta_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, theta_allsources{:,2}, theta_allsources{:,4});
    
    beta_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, beta_allsources{:,1}, beta_allsources{:,3});
    beta_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, beta_allsources{:,2}, beta_allsources{:,4});
    
    beta_btwn_stat_l1p1_l2p2 = ft_sourcestatistics(cfg, beta_btwn_allsources{:,1}, beta_btwn_allsources{:,3});
    beta_btwn_stat_l1p3_l2p3 = ft_sourcestatistics(cfg, beta_btwn_allsources{:,2}, beta_btwn_allsources{:,4});
    
    % interpolate onto MNI
    fprintf('\n*** Interpolating onto MNI. ***\n');
    
    mri = ft_read_mri(fullfile(rootdir, 'processed', 'combined', 'average305_t1_tal_lin.nii'));
    mri.coordsys = 'mni';
    
    cfg = [];
    cfg.parameter = 'stat';
    
    theta_stat_l1p1_l2p2_interp = ft_sourceinterpolate(cfg, theta_stat_l1p1_l2p2, mri);
    theta_stat_l1p3_l2p3_interp = ft_sourceinterpolate(cfg, theta_stat_l1p3_l2p3, mri);
    
    beta_stat_l1p1_l2p2_interp = ft_sourceinterpolate(cfg, beta_stat_l1p1_l2p2, mri);
    beta_stat_l1p3_l2p3_interp = ft_sourceinterpolate(cfg, beta_stat_l1p3_l2p3, mri);
    
    beta_btwn_stat_l1p1_l2p2_interp = ft_sourceinterpolate(cfg, beta_btwn_stat_l1p1_l2p2, mri);
    beta_btwn_stat_l1p3_l2p3_interp = ft_sourceinterpolate(cfg, beta_btwn_stat_l1p3_l2p3, mri);
    
    %%
    theta_stat_l1p1_l2p2_interp.nicemask = helper_make_mask(theta_stat_l1p1_l2p2_interp.stat, [0.25 0.8]);
    theta_stat_l1p3_l2p3_interp.nicemask = helper_make_mask(theta_stat_l1p3_l2p3_interp.stat, [0.25 0.8]);
    
    beta_stat_l1p1_l2p2_interp.nicemask = helper_make_mask(beta_stat_l1p1_l2p2_interp.stat, [0.65 0.8]);
    beta_stat_l1p3_l2p3_interp.nicemask = helper_make_mask(beta_stat_l1p3_l2p3_interp.stat, [0.65 0.8]);
    
    beta_btwn_stat_l1p1_l2p2_interp.nicemask = helper_make_mask(beta_stat_l1p1_l2p2_interp.stat, [0.65 0.8]);
    beta_btwn_stat_l1p3_l2p3_interp.nicemask = helper_make_mask(beta_stat_l1p3_l2p3_interp.stat, [0.65 0.8]);
    
    %%
    cfg = [];
    cfg.parameter = 'pow';
    cfg.method = 'analytic';
    cfg.correctm = 'no';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.tail = 0;
    
    nobs = size(theta_allsources, 1);
    cfg.design = [
        ones(1, nobs)*1 ones(1, nobs)*2
        1:nobs 1:nobs
    ];
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    theta_stat_l1p1_l1p3 = ft_sourcestatistics(cfg, theta_allsources{:,1}, theta_allsources{:,2});
    theta_stat_l2p2_l2p3 = ft_sourcestatistics(cfg, theta_allsources{:,3}, theta_allsources{:,4});
    
    cfg = [];
    cfg.parameter = 'stat';
    theta_stat_l1p1_l1p3_interp = ft_sourceinterpolate(cfg, theta_stat_l1p1_l1p3, mri);
    theta_stat_l2p2_l2p3_interp = ft_sourceinterpolate(cfg, theta_stat_l2p2_l2p3, mri);
    
    %%
    cfg = [];
    
    %%
    cfg = [];
    cfg.atlas = fullfile('/home', 'common', 'matlab', 'fieldtrip', 'template', 'atlas', 'aal', 'ROI_MNI_V4.nii');
    cfg.funparameter = 'stat';
    %cfg.maskparameter = 'nicemask';
    cfg.method = 'ortho';
    %cfg.roi = {'Hippocampus_L', 'Hippocampus_R', 'ParaHippocampal_L', 'ParaHippocampal_R', 'Frontal_Sup_L', 'Frontal_Sup_R'};
    %cfg.roi = {'Hippocampus_R', 'Frontal_Sup_L', 'Heschl_L', 'Temporal_Sup_L'};
    %cfg.roi = {'Hippocampus_R'};
    
    %cfg.location = [42.9 -30.5 -9.3];
    
    %ft_sourceplot(cfg, theta_stat_l1p1_l2p2_interp);
    %ft_sourceplot(cfg, theta_stat_l1p3_l2p3_interp);
    
    ft_sourceplot(cfg, theta_stat_l1p1_l1p3_interp);
    ft_sourceplot(cfg, theta_stat_l2p2_l2p3_interp);
    
    %cfg.location = [-12.1 23.5 59.7];
    %ft_sourceplot(cfg, theta_stat_l1p1_l2p2_interp);
    %ft_sourceplot(cfg, theta_stat_l1p3_l2p3_interp);
    
    %ft_sourceplot(cfg, beta_stat_l1p1_l2p2_interp);
    %ft_sourceplot(cfg, beta_stat_l1p3_l2p3_interp);
    
    %ft_sourceplot(cfg, beta_btwn_stat_l1p1_l2p2_interp);
    %ft_sourceplot(cfg, beta_btwn_stat_l1p3_l2p3_interp);
    
    %% 
    fprintf('\n*** Aggregating data across subjects ***\n');
    
    ind_allfreqs = {};
    ind_allconds = {};
    ind_condslabels = {};
    
    evo_allfreqs = {};
    evo_allconds = {};
    evo_condslabels = {};
    
    btw_allfreqs = {};
    btw_allconds = {};
    btw_condslabels = {};
    
    for k=1:numel(subjects)
        
        % make sure we include only data from participants where we made
        % the decision to include their data in analyses
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end
        
        load(fullfile(subjects(k).out, 'subj_tfr.mat'), 'freqs', 'conds', 'condslabels');
        
        ind_allfreqs{k} = freqs;
        ind_allconds{k} = conds;
        ind_condslabels = condslabels;
        
        load(fullfile(subjects(k).out, 'subj_tfr_evoked.mat'), 'freqs', 'conds', 'condslabels');
        
        evo_allfreqs{k} = freqs;
        evo_allconds{k} = conds;
        evo_condslabels = condslabels;
        
        load(fullfile(subjects(k).out, 'subj_tfr_btwn.mat'), 'freqs', 'conds', 'condslabels');
        
        btw_allfreqs{k} = freqs;
        btw_allconds{k} = conds;
        btw_condslabels = condslabels;
    end
    
    ind_allfreqs = cat(1, ind_allfreqs{:}); % subject x condition
    evo_allfreqs = cat(1, evo_allfreqs{:}); % subject x condition
    btw_allfreqs = cat(1, btw_allfreqs{:}); % subject x condition
    
    
    %%
    
    % load neighbours
    fprintf('\n*** Loading neighbours ***\n');
    
    cfg = [];
    cfg.method = 'template';
    cfg.template = 'ctf275_neighb.mat';
    neighbours = ft_prepare_neighbours(cfg);
    
    %%
    
    % cluster-based permutations 
    fprintf('\n*** Computing cluster-based permutations ***\n');
    
    % setup configuration to use
    cfg = [];
    cfg.method = 'montecarlo';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.clusterthreshold = 'parametric';
    cfg.clusterstatistic = 'maxsum';
    cfg.numrandomization = 1000;
    cfg.correctm = 'cluster';
    cfg.neighbours = neighbours;
    cfg.minnbchan = 2;
    cfg.tail = 0;
    cfg.clustertail = 0;
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2
        1:nobs 1:nobs
    ]';
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    % compute theta responses
    cfg.frequency = [1 7];
    cfg.latency = [0.00 1.00];
    
    % induced: L1P1 - L1P3
    ind_theta_l1p1_l1p3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    % induced: L2P2 - L2P3
    ind_theta_l2p2_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    % induced: L1P1 - L2P2
    ind_theta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    % induced: L1P3 - L2P3
    ind_theta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    
    % evoked: L1P1 - L1P3
    evo_theta_l1p1_l1p3 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,2});
    % evoked: L2P2 - L2P3
    evo_theta_l2p2_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,3}, evo_allfreqs{:,4});
    % evoked: L1P1 - L2P2
    evo_theta_l1p1_l2p2 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,3});
    % evoked: L1P3 - L2P3
    evo_theta_l1p3_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,2}, evo_allfreqs{:,4});
    
    %%
    cfg = [];
    cfg.method = 'montecarlo';
    cfg.statistic = 'ft_statfun_depsamplesFunivariate';
    cfg.clusterthreshold = 'parametric';
    cfg.clusterstatistic = 'maxsum';
    cfg.numrandomization = 1000;
    cfg.correctm = 'cluster';
    cfg.neighbours = neighbours;
    cfg.minnbchan = 2;
    cfg.tail = 1;
    cfg.clustertail = 1;
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2 ones(1,nobs)*3 ones(1,nobs)*4
        1:nobs 1:nobs 1:nobs 1:nobs
    ]';
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    % compute theta responses
    cfg.frequency = [1 8];
    cfg.latency = [0.4 0.75];
    
    % induced: L1P1 - L1P3
    ind_theta = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    %%
    evo_theta = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,2}, evo_allfreqs{:,3}, evo_allfreqs{:,4});
    
    %%
    cfg.frequency = [13 20];
    cfg.latency = [0.15 0.75];
    
    beta_low = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    cfg.frequency = [21 30];
    cfg.latency = [0.15 1.00];
    beta_high = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    
    %%
    helper_tfrclusterplot(ind_theta, 0.7, true);
    
    %%
    helper_tfrclusterplot(evo_theta, 0.9, true);
    
    %%
    helper_tfrclusterplot(beta_low, 0.9, true);
    
    %%
    helper_tfrclusterplot(beta_high, 0.9, true);
    
    %%
    cfg.frequency = [1 8];
    cfg.latency = [0.7 1.0];
    cfg.statistic = 'ft_statfun_depsamplesT'; % 'ft_statfun_actvsblT';
    cfg.tail = 0;
    cfg.clustertail = 0;
    cfg.design = [
                    ones(1, nobs)*1 ones(1,nobs)*2
                    1:nobs 1:nobs
    ];
    v_late_ind_theta_bsl = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    v_late_ind_theta_bsl2 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    v_late_ind_theta_bsl3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    v_late_ind_theta_bsl4 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    
    %%
    cfg.latency = [0.35 0.75];
    
    late_ind_theta_bsl = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    late_ind_theta_bsl2 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    late_ind_theta_bsl3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    late_ind_theta_bsl4 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(v_late_ind_theta_bsl4, 0.9, true);
    
    %%
    helper_tfrclusterplot(late_ind_theta_bsl4, 0.9, true);
    
    %%
    helper_tfrclusterplot(ind_theta_bsl, 0.9, true);
    
    %%
    helper_tfrclusterplot(ind_theta_bsl2, 0.9, true);
    
    %%
    diff_L1 = {};
    diff_L2 = {};
    diff_ve = {};
    diff_st = {};
    
    for k = 1:size(ind_allfreqs, 1)
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.operation = '(x1-x2)';
        
        diff_L1{k} = ft_math(cfg, ind_allfreqs{k,1}, ind_allfreqs{k,2});
        diff_L2{k} = ft_math(cfg, ind_allfreqs{k,3}, ind_allfreqs{k,3});
        diff_ve{k} = ft_math(cfg, ind_allfreqs{k,1}, ind_allfreqs{k,3});
        diff_st{k} = ft_math(cfg, ind_allfreqs{k,2}, ind_allfreqs{k,4});
    end
    
    %%
    cfg = [];
    cfg.method = 'montecarlo';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.clusterthreshold = 'parametric';
    cfg.clusterstatistic = 'maxsum';
    cfg.numrandomization = 1000;
    cfg.correctm = 'cluster';
    cfg.neighbours = neighbours;
    cfg.minnbchan = 2;
    cfg.tail = 0;
    cfg.clustertail = 0;
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2
        1:nobs 1:nobs
    ]';
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    % compute theta responses
    cfg.frequency = [1 8];
    cfg.latency = [0.15 0.75];
    %cfg.computecritval = 'no';
    
    
    %%
    theta_L1_L2 = ft_freqstatistics(cfg, diff_L1{:}, diff_L2{:});
    theta_ve_st = ft_freqstatistics(cfg, diff_ve{:}, diff_st{:});
    
    %%
    helper_tfrclusterplot(theta_L1_L2, 0.6, true);
    
    %%
    helper_tfrclusterplot(theta_ve_st, 0.6, true)
    
    %%
    % ind lexicality
    ind_theta_lex_L1 = {};
    ind_theta_lex_L2 = {};
    
    for k = 1:size(ind_allfreqs, 1)
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.operation = '(x1-x2)';
        
        ind_theta_lex_L1{k} = ft_math(cfg, ind_allfreqs{k,1}, ind_allfreqs{k,2});
        ind_theta_lex_L2{k} = ft_math(cfg, ind_allfreqs{k,3}, ind_allfreqs{k,4});
    end
    
    %%
    % grand effect
    cfg = [];
    cfg.method = 'montecarlo';
    cfg.statistic = 'depsamplesFmultivariate';
    cfg.clusterthreshold = 'parametric';
    cfg.clusterstatistic = 'maxsum';
    cfg.numrandomization = 1000;
    cfg.correctm = 'cluster';
    cfg.neighbours = neighbours;
    cfg.minnbchan = 2;
    cfg.tail = 1;
    cfg.clustertail = 1;
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2 ones(1,nobs)*3 ones(1,nobs)*4
        1:nobs 1:nobs 1:nobs 1:nobs
    ];
    cfg.ivar = 1;
    cfg.uvar = 2;
    %%
    
    % compute theta responses
    cfg.frequency = [1 7];
    cfg.latency = [0.00 1.00];
    
    ind_theta = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(ind_theta, 0.3, true);
    
    %%
    cfg.frequency = [17 23];
    cfg.latency = [0.25 1.00];
    
    ind_beta = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(ind_beta, 0.6, true);
    
    %%
    cfg.frequency = [1 30];
    cfg.latency = [0.00 1.00];
    
    ind_full = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2}, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(ind_full, 1.0, true);
    
    %%
    cfg.frequency = [1 30];
    cfg.latency = [0.00 1.00];
    
    evo_full = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,2}, evo_allfreqs{:,3}, evo_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(ind_full, 1.0, true);
    
    %%
    cfg.frequency = [1 30];
    cfg.latency = [0.00 1.00];
    btw_full = ft_freqstatistics(cfg, btw_allfreqs{:,1}, btw_allfreqs{:,2}, btw_allfreqs{:,3}, btw_allfreqs{:,4});
    
    %%
    helper_tfrclusterplot(btw_full, 1.0, true);
    
    %%
    ind_ga_1 = ft_freqgrandaverage([], ind_allfreqs{:,1});
    ind_ga_2 = ft_freqgrandaverage([], ind_allfreqs{:,2});
    ind_ga_3 = ft_freqgrandaverage([], ind_allfreqs{:,3});
    ind_ga_4 = ft_freqgrandaverage([], ind_allfreqs{:,4});
    
    cfg = [];
    cfg.avgoverchan = 'yes';
    ind_ga_1_avg = ft_selectdata(cfg, ind_ga_1);
    ind_ga_2_avg = ft_selectdata(cfg, ind_ga_2);
    ind_ga_3_avg = ft_selectdata(cfg, ind_ga_3);
    ind_ga_4_avg = ft_selectdata(cfg, ind_ga_4);
    
    %%
    ind_lex_L1 = {};
    ind_lex_L2 = {};
    
    for k = 1:size(ind_allfreqs, 1)
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.operation = '(x1-x2)';
        ind_lex_L1{k} = ft_math(cfg, ind_allfreqs{k,1}, ind_allfreqs{k,2});
        ind_lex_L2{k} = ft_math(cfg, ind_allfreqs{k,3}, ind_allfreqs{k,4});
    end
    
    ind_L1_ga = ft_freqgrandaverage([], ind_lex_L1{:});
    ind_L2_ga = ft_freqgrandaverage([], ind_lex_L2{:});
    
    cfg = [];
    cfg.avgoverchan = 'yes';
    ind_L1_ga_avg = ft_selectdata(cfg, ind_L1_ga);
    ind_L2_ga_avg = ft_selectdata(cfg, ind_L2_ga);
    
    %%
    ind_L1L2_diff = {};
    
    for k = 1:size(ind_allfreqs, 1)
        cfg = [];
        cfg.parameter = 'powspctrm';
        cfg.operation = '(x1-x2)';
        ind_L1L2_diff{k} = ft_math(cfg, ind_lex_L1{k}, ind_lex_L2{k});
    end
    
    ind_L1L2_diff_ga = ft_freqgrandaverage([], ind_L1L2_diff{:});
    
    cfg = [];
    cfg.avgoverchan = 'yes';
    ind_L1L2_diff_ga_avg = ft_selectdata(cfg, ind_L1L2_diff_ga);
    
    %%
    cfg = [];
    cfg.baseline = [-0.5 -0.1];
    cfg.baselinetype = 'absolute';
    cfg.parameter = 'powspctrm';
    cfg.interactive = 'yes';
    ft_singleplotTFR(cfg, ind_L1L2_diff_ga_avg);
    
    
    
    %%
    cfg = [];
    %cfg.baseline = [-0.4 -0.1];
    %cfg.baselinetype = 'absolute';
    %cfg.baseline = [-0.5 -0.1];
    %cfg.baselinetype = 'absolute';
    cfg.parameter = 'powspctrm';
    cfg.interactive = 'yes';
    ft_singleplotTFR(cfg, ind_L1_ga_avg);
    ft_singleplotTFR(cfg, ind_L2_ga_avg);
    
    %%
    cfg = [];
    cfg.baseline = [-0.4 -0.1];
    cfg.baselinetype = 'absolute';
    cfg.parameter = 'powspctrm';
    cfg.interactive = 'yes';
    ft_singleplotTFR(cfg, ind_ga_1_avg);
    ft_singleplotTFR(cfg, ind_ga_2_avg);
    ft_singleplotTFR(cfg, ind_ga_3_avg);
    ft_singleplotTFR(cfg, ind_ga_4_avg);
    
    %%
    cfg = [];
    cfg.method = 'montecarlo';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.clusterthreshold = 'parametric';
    cfg.clusterstatistic = 'maxsum';
    cfg.numrandomization = 1000;
    cfg.correctm = 'cluster';
    cfg.neighbours = neighbours;
    cfg.minnbchan = 2;
    cfg.tail = 0;
    cfg.clustertail = 0;
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2
        1:nobs 1:nobs
    ]';
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    % compute theta response
    cfg.frequency = [1 7];
    cfg.latency = [0.00 1.00];
    
    ind_theta_lex_L1_L2 = ft_freqstatistics(cfg, ind_theta_lex_L1{:}, ind_theta_lex_L2{:});
    
    %%
    
    % compute beta responses
    cfg.frequency = [17 23];
    cfg.latency = [0.25 1.00];
    
    % early: L1P1 - L2P2
    erl_beta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    % early: L1P3 - L2P3
    erl_beta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    % late: L1P1 - L2P2
    lat_beta_l1p1_l2p2 = ft_freqstatistics(cfg, btw_allfreqs{:,1}, btw_allfreqs{:,3});
    % late: L1P3 - L2P3
    lat_beta_l1p3_l2p3 = ft_freqstatistics(cfg, btw_allfreqs{:,2}, btw_allfreqs{:,4});
    
    %%
    stat = ind_theta_lex_L1_L2;
    %target_freq = [1, 8];
    %target_time = [-1.00, 2.00];
    %tmp = stat.negclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),find(stat.time >= target_time(1) & stat.time <= target_time(2)));
    %plot_negclus = [mode(tmp(tmp>0))];
    %tmp = stat.posclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),find(stat.time >= target_time(1) & stat.time <= target_time(2)));
    %plot_posclus = [mode(tmp(tmp>0))];
    %helper_tfrclusterplot(stat, 1.5, 1, plot_posclus, plot_negclus);
    helper_tfrclusterplot(stat, 0.15, true);
    
    %%
    chanmask = squeeze(any(any(stat.negclusterslabelmat==1,2),3));
    tfrmask = squeeze(any(stat.negclusterslabelmat==1,1));
    
    cfg = [];
    cfg.channel = stat.label(chanmask);
    cfg.avgoverchan = 'yes';
    tmpstat = ft_selectdata(cfg, ind_theta_l1p1_l1p3);
    tmpstat.mask = reshape(tfrmask, [1 size(tfrmask)]);
    tmpstat2 = ft_selectdata(cfg, ind_theta_l2p2_l2p3);
    tmpstat2.mask = reshape(tfrmask, [1 size(tfrmask)]);
    
    cfg = [];
    cfg.parameter = 'stat';
    cfg.maskparameter = 'mask';
    cfg.maskalpha = 0.3;
    cfg.colormap = brewermap(256, '*RdYlBu');
    cfg.colorbar = 'yes';
    cfg.title = '';
    ft_singleplotTFR(cfg, tmpstat);
    ft_singleplotTFR(cfg, tmpstat2);
    
    %%
    stat = erl_beta_l1p3_l2p3;
    ft_clusterplot([], stat);