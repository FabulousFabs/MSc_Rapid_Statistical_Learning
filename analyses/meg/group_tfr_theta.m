% @Description: Compute group-level clusters for low (<8Hz) frequencies.

function group_tfr_theta(subjects, rootdir)
    % load all data
    fprintf('\n*** Aggregating data across subjects ***\n');
    
    ind_allfreqs = {};
    evo_allfreqs = {};
    
    ind_L1_diff = {};
    ind_L2_diff = {};
    
    ind_L1_avg = {};
    ind_L2_avg = {};
    ind_veri_avg = {};
    ind_stat_avg = {};
    
    allconds = {};
    condslabels = {};
    
    for k=1:numel(subjects)
        % make sure we include only data from participants where we made
        % the decision to include their data in analyses
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end
        
        load(fullfile(subjects(k).out, 'subj_tfr.mat'), 'freqs', 'conds', 'condslabels');
        
        ind_allfreqs{k} = freqs;
        allconds{k} = conds;
        condslabels = condslabels;
        
        ind_L1_diff{k} = freqs{1};
        ind_L1_diff{k}.powspctrm = freqs{1}.powspctrm - freqs{2}.powspctrm;
        ind_L2_diff{k} = freqs{3};
        ind_L2_diff{k}.powspctrm = freqs{3}.powspctrm - freqs{4}.powspctrm;
        
        ind_L1_avg{k} = freqs{1};
        ind_L1_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{2}.powspctrm) ./ 2;
        ind_L2_avg{k} = freqs{3};
        ind_L2_avg{k}.powspctrm = (freqs{3}.powspctrm + freqs{4}.powspctrm) ./ 2;
        
        ind_veri_avg{k} = freqs{1};
        ind_veri_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{3}.powspctrm) ./ 2;
        ind_stat_avg{k} = freqs{2};
        ind_stat_avg{k}.powspctrm = (freqs{2}.powspctrm + freqs{4}.powspctrm) ./ 2;
        
        clear freqs;
        
        load(fullfile(subjects(k).out, 'subj_tfr_evoked.mat'), 'freqs');
        
        evo_allfreqs{k} = freqs;
        
        clear freqs;
    end
    
    
    ind_allfreqs = cat(1, ind_allfreqs{:}); % subject x condition
    evo_allfreqs = cat(1, evo_allfreqs{:}); % subject x condition
    
    
    ind_L1_diff = ind_L1_diff(~cellfun('isempty', ind_L1_diff))';
    ind_L2_diff = ind_L2_diff(~cellfun('isempty', ind_L2_diff))';
    
    ind_L1_avg = ind_L1_avg(~cellfun('isempty', ind_L1_avg))';
    ind_L2_avg = ind_L2_avg(~cellfun('isempty', ind_L2_avg))';
    ind_veri_avg = ind_veri_avg(~cellfun('isempty', ind_veri_avg))';
    ind_stat_avg = ind_stat_avg(~cellfun('isempty', ind_stat_avg))';
    
    
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
    nobs = size(ind_allfreqs, 1);
    cfg.design = [
        ones(1,nobs)*1 ones(1,nobs)*2
        1:nobs 1:nobs
    ]';
    cfg.ivar = 1;
    cfg.uvar = 2;
    
    % compute theta
    cfg.latency = [0.1 0.3];
    cfg.frequency = [1 7];
    
    ind_theta_l1p1_l1p3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    ind_theta_l2p2_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    ind_theta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    ind_theta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    
    diff_theta_L1_L2 = ft_freqstatistics(cfg, ind_L1_diff{:}, ind_L2_diff{:});
    avg_theta_L1_L2 = ft_freqstatistics(cfg, ind_L1_avg{:}, ind_L2_avg{:});
    avg_theta_veri_stat = ft_freqstatistics(cfg, ind_veri_avg{:}, ind_stat_avg{:});
    
    % compute delta
    cfg.latency = [0.5 0.8];
    cfg.frequency = [1 4];
    ind_delta_l1p1_l1p3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    ind_delta_l2p2_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    ind_delta_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    ind_delta_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    
    diff_delta_L1_L2 = ft_freqstatistics(cfg, ind_L1_diff{:}, ind_L2_diff{:});
    avg_delta_L1_L2 = ft_freqstatistics(cfg, ind_L1_avg{:}, ind_L2_avg{:});
    avg_delta_veri_stat = ft_freqstatistics(cfg, ind_veri_avg{:}, ind_stat_avg{:});
    
    % compute evoked theta
    cfg.latency = [0.1 0.3];
    cfg.frequency = [1 7];
    evo_theta_l1p1_l1p3 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,2});
    evo_theta_l2p2_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,3}, evo_allfreqs{:,4});
    evo_theta_l1p1_l2p2 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,3});
    evo_theta_l1p3_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,2}, evo_allfreqs{:,4});
    
    
    % compute evoked delta
    cfg.latency = [0.5 0.8];
    cfg.frequency = [1 4];
    evo_delta_l1p1_l1p3 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,2});
    evo_delta_l2p2_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,3}, evo_allfreqs{:,4});
    evo_delta_l1p1_l2p2 = ft_freqstatistics(cfg, evo_allfreqs{:,1}, evo_allfreqs{:,3});
    evo_delta_l1p3_l2p3 = ft_freqstatistics(cfg, evo_allfreqs{:,2}, evo_allfreqs{:,4});
    
    
    % plot all data
    fprintf('\n*** Plotting results. ***\n');
    
    % plot theta
    figure; helper_tfrclusterplot(ind_theta_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_theta_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_theta_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_theta_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_theta_l1p3_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(diff_theta_L1_L2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_diff_theta_L1_L2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_diff_theta_L1_L2.png'), 'png');
    
    figure; helper_tfrclusterplot(avg_theta_L1_L2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_theta_L1_L2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_theta_L1_L2.png'), 'png');
    
    figure; helper_tfrclusterplot(avg_theta_veri_stat, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_theta_veri_stat.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_theta_veri_stat.png'), 'png');
    
    
    % plot delta
    figure; helper_tfrclusterplot(ind_delta_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_delta_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_delta_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_delta_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_delta_l1p3_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(diff_delta_L1_L2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_diff_delta_L1_L2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_diff_delta_L1_L2.png'), 'png');
    
    figure; helper_tfrclusterplot(avg_delta_L1_L2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_delta_L1_L2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_delta_L1_L2.png'), 'png');
    
    figure; helper_tfrclusterplot(avg_delta_veri_stat, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_delta_veri_stat.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_avg_delta_veri_stat.png'), 'png');
    
    
    % plot evo theta
    figure; helper_tfrclusterplot(evo_theta_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_theta_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_theta_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_theta_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_theta_l1p3_l2p3.png'), 'png');
    
    
    % plot evo delta
    figure; helper_tfrclusterplot(evo_delta_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_delta_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_delta_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(evo_delta_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_evo_delta_l1p3_l2p3.png'), 'png');
    
    
    % save results to look up p-values later
    fprintf('\n*** Saving results. ***\n');
    
    save(fullfile(rootdir, 'results', 'group_tfr_theta.mat'));
end