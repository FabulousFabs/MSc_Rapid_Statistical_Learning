% @Description: Compute group-level statistics for TFR analyses.

function group_tfr(subjects)
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
        ind_allconds{k} = allconds;
        ind_condslabels = condslabels;
        
        load(fullfile(subjects(k).out, 'subj_tfr_evoked.mat'), 'freqs', 'conds', 'condslabels');
        
        evo_allfreqs{k} = freqs;
        evo_allconds{k} = allconds;
        evo_condslabels = condslabels;
        
        load(fullfile(subjects(k).out, 'subj_tfr_btwn.mat'), 'freqs', 'conds', 'condslabels');
        
        btw_allfreqs{k} = freqs;
        btw_allconds{k} = allconds;
        btw_condslabels = condslabels;
    end
    
    ind_allfreqs = cat(1, ind_allfreqs{:}); % subject x condition
    evo_allfreqs = cat(1, evo_allfreqs{:}); % subject x condition
    btw_allfreqs = cat(1, btw_allfreqs{:}); % subject x condition
    
    % load neighbours
    fprintf('\n*** Loading neighbours ***\n');
    
    cfg = [];
    cfg.method = 'template';
    cfg.template = 'ctf275_neighb.mat';
    neighbours = ft_prepare_neighbours(cfg);
    
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
    nobs = size(allfreqs, 1);
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
    ind_theta_l1p1_l1p3 = ft_freqstatistics(cfg, ind_allfreqs{1}, ind_allfreqs{2});
    % induced: L2P2 - L2P3
    ind_theta_l2p2_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{3}, ind_allfreqs{4});
    % induced: L1P1 - L2P2
    ind_theta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{1}, ind_allfreqs{3});
    % induced: L1P3 - L2P3
    ind_theta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{2}, ind_allfreqs{4});
    
    % evoked: L1P1 - L1P3
    evo_theta_l1p1_l1p3 = ft_freqstatistics(cfg, evo_allfreqs{1}, evo_allfreqs{2});
    % evoked: L2P2 - L2P3
    evo_theta_l2p2_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{3}, evo_allfreqs{4});
    % evoked: L1P1 - L2P2
    evo_theta_l1p1_l2p2 = ft_freqstatistics(cfg, evo_allfreqs{1}, evo_allfreqs{3});
    % evoked: L1P3 - L2P3
    evo_theta_l1p3_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{2}, evo_allfreqs{4});
    
    % compute beta responses
    cfg.frequency = [17 23];
    cfg.latency = [0.25 1.00];
    
    % early: L1P1 - L2P2
    erl_beta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{1}, ind_allfreqs{3});
    % early: L1P3 - L2P3
    erl_beta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{2}, ind_allfreqs{4});
    % late: L1P1 - L2P2
    lat_beta_l1p1_l2p2 = ft_freqstatistics(cfg, btw_allfreqs{1}, btw_allfreqs{3});
    % late: L1P3 - L2P3
    lat_beta_l1p3_l2p3 = ft_freqstatistics(cfg, btw_allfreqs{2}, btw_allfreqs{4});
    
    %%
    %target_freq = [18, 30];
    %tmp = stat.negclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),:);
    %plot_negclus = [mode(tmp(tmp>0))];
    %tmp = stat.posclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),:);
    %plot_posclus = [mode(tmp(tmp>0))];
    %helper_tfrclusterplot(stat, 1.5, 1, plot_posclus, plot_negclus);
    
    %%
    %target_freq = [18, 24];
    %target_time = [0.25, 1.00];
    %tmp = stat.negclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),find(stat.time >= target_time(1) & stat.time <= target_time(2)));
    %plot_negclus = [mode(tmp(tmp>0))];
    %tmp = stat.posclusterslabelmat(:,find(stat.freq >= target_freq(1) & stat.freq <= target_freq(2)),find(stat.time >= target_time(1) & stat.time <= target_time(2)));
    %plot_posclus = [mode(tmp(tmp>0))];
    %helper_tfrclusterplot(stat, 0.05, 1, plot_posclus, plot_negclus);
end