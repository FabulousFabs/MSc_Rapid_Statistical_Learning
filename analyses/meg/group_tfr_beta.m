% @Description: Compute group-level beta clusters.

function group_tfr_beta(subjects, rootdir)
    % load all data
    fprintf('\n*** Aggregating data across subjects ***\n');
    
    ind_allfreqs = {};
    prm_allfreqs = {};
    
    ind_L1_diff = {};
    ind_L2_diff = {};
    ind_veri_diff = {};
    ind_stat_diff = {};
    
    ind_L1_avg = {};
    ind_L2_avg = {};
    ind_veri_avg = {};
    ind_stat_avg = {};
    
    prm_L1_diff = {};
    prm_L2_diff = {};
    prm_veri_diff = {};
    prm_stat_diff = {};
    
    prm_L1_avg = {};
    prm_L2_avg = {};
    prm_veri_avg = {};
    prm_stat_avg = {};
    
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
        ind_veri_diff{k} = freqs{1};
        ind_veri_diff{k}.powspctrm = freqs{1}.powspctrm - freqs{3}.powspctrm;
        ind_stat_diff{k} = freqs{2};
        ind_stat_diff{k}.powspctrm = freqs{2}.powspctrm - freqs{4}.powspctrm;
        
        ind_L1_avg{k} = freqs{1};
        ind_L1_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{2}.powspctrm) ./ 2;
        ind_L2_avg{k} = freqs{3};
        ind_L2_avg{k}.powspctrm = (freqs{3}.powspctrm + freqs{4}.powspctrm) ./ 2;
        ind_veri_avg{k} = freqs{1};
        ind_veri_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{3}.powspctrm) ./ 2;
        ind_stat_avg{k} = freqs{2};
        ind_stat_avg{k}.powspctrm = (freqs{2}.powspctrm + freqs{4}.powspctrm) ./ 2;
        
        clear freqs;
        
        load(fullfile(subjects(k).out, 'subj_tfr_prompt.mat'), 'freqs');
        
        prm_allfreqs{k} = freqs;
        
        prm_L1_diff{k} = freqs{1};
        prm_L1_diff{k}.powspctrm = freqs{1}.powspctrm - freqs{2}.powspctrm;
        prm_L2_diff{k} = freqs{3};
        prm_L2_diff{k}.powspctrm = freqs{3}.powspctrm - freqs{4}.powspctrm;
        prm_veri_diff{k} = freqs{1};
        prm_veri_diff{k}.powspctrm = freqs{1}.powspctrm - freqs{3}.powspctrm;
        prm_stat_diff{k} = freqs{2};
        prm_stat_diff{k}.powspctrm = freqs{2}.powspctrm - freqs{4}.powspctrm;
        
        prm_L1_avg{k} = freqs{1};
        prm_L1_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{2}.powspctrm) ./ 2;
        prm_L2_avg{k} = freqs{3};
        prm_L2_avg{k}.powspctrm = (freqs{3}.powspctrm + freqs{4}.powspctrm) ./ 2;
        prm_veri_avg{k} = freqs{1};
        prm_veri_avg{k}.powspctrm = (freqs{1}.powspctrm + freqs{3}.powspctrm) ./ 2;
        prm_stat_avg{k} = freqs{2};
        prm_stat_avg{k}.powspctrm = (freqs{2}.powspctrm + freqs{4}.powspctrm) ./ 2;
        
        clear freqs;
    end
    
    ind_allfreqs = cat(1, ind_allfreqs{:}); % subject x condition
    prm_allfreqs = cat(1, prm_allfreqs{:}); % subject x condition
    
    ind_L1_diff = ind_L1_diff(~cellfun('isempty', ind_L1_diff))';
    ind_L2_diff = ind_L2_diff(~cellfun('isempty', ind_L2_diff))';
    ind_veri_diff = ind_veri_diff(~cellfun('isempty', ind_veri_diff))';
    ind_stat_diff = ind_stat_diff(~cellfun('isempty', ind_stat_diff))';
    
    prm_L1_diff = prm_L1_diff(~cellfun('isempty', prm_L1_diff))';
    prm_L2_diff = prm_L2_diff(~cellfun('isempty', prm_L2_diff))';
    prm_veri_diff = prm_veri_diff(~cellfun('isempty', prm_veri_diff))';
    prm_stat_diff = prm_stat_diff(~cellfun('isempty', prm_stat_diff))';
    
    ind_L1_avg = ind_L1_avg(~cellfun('isempty', ind_L1_avg))';
    ind_L2_avg = ind_L2_avg(~cellfun('isempty', ind_L2_avg))';
    ind_veri_avg = ind_veri_avg(~cellfun('isempty', ind_veri_avg))';
    ind_stat_avg = ind_stat_avg(~cellfun('isempty', ind_stat_avg))';
    
    prm_L1_avg = prm_L1_avg(~cellfun('isempty', prm_L1_avg))';
    prm_L2_avg = prm_L2_avg(~cellfun('isempty', prm_L2_avg))';
    prm_veri_avg = prm_veri_avg(~cellfun('isempty', prm_veri_avg))';
    prm_stat_avg = prm_stat_avg(~cellfun('isempty', prm_stat_avg))';
    
    
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
    
    
    % compute beta responses (main TOI)
    cfg.latency = [0.6 0.8];
    cfg.frequency = [20 23];
    
    ind_beta_high_L1_L2_avg = ft_freqstatistics(cfg, ind_L1_avg{:}, ind_L2_avg{:});
    ind_beta_high_veri_stat_avg = ft_freqstatistics(cfg, ind_veri_avg{:}, ind_stat_avg{:});
    
    ind_beta_high_l1p1_l1p3 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,2});
    ind_beta_high_l2p2_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,3}, ind_allfreqs{:,4});
    ind_beta_high_l1p1_l2p2 = ft_freqstatistics(cfg, ind_allfreqs{:,1}, ind_allfreqs{:,3});
    ind_beta_high_l1p3_l2p3 = ft_freqstatistics(cfg, ind_allfreqs{:,2}, ind_allfreqs{:,4});
    ind_beta_high_L1_L2_diff = ft_freqstatistics(cfg, ind_L1_diff{:}, ind_L2_diff{:});
    
    
    % compute beta responses (ITI TOI)
    cfg.latency = [0.3 0.6];
    cfg.frequency = [18 22];
    
    prm_beta_high_L1_L2_avg = ft_freqstatistics(cfg, prm_L1_avg{:}, prm_L2_avg{:});
    prm_beta_high_veri_stat_avg = ft_freqstatistics(cfg, prm_veri_avg{:}, prm_stat_avg{:});
    prm_beta_high_l1p1_l1p3 = ft_freqstatistics(cfg, prm_allfreqs{:,1}, prm_allfreqs{:,2});
    prm_beta_high_l2p2_l2p3 = ft_freqstatistics(cfg, prm_allfreqs{:,3}, prm_allfreqs{:,4});
    prm_beta_high_l1p1_l2p2 = ft_freqstatistics(cfg, prm_allfreqs{:,1}, prm_allfreqs{:,3});
    prm_beta_high_l1p3_l2p3 = ft_freqstatistics(cfg, prm_allfreqs{:,2}, prm_allfreqs{:,4});
    prm_beta_high_L1_L2_diff = ft_freqstatistics(cfg, prm_L1_diff{:}, prm_L2_diff{:});
    
    
    %% plot results (main TOI)
    figure; helper_tfrclusterplot(ind_beta_high_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_beta_high_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_beta_high_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(ind_beta_high_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_ind_beta_high_l1p3_l2p3.png'), 'png');
    
    
    % plot results (prompt TOI)
    figure; helper_tfrclusterplot(prm_beta_high_l1p1_l1p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p1_l1p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p1_l1p3.png'), 'png');
    
    figure; helper_tfrclusterplot(prm_beta_high_l2p2_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l2p2_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l2p2_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(prm_beta_high_l1p1_l2p2, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p1_l2p2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p1_l2p2.png'), 'png');
    
    figure; helper_tfrclusterplot(prm_beta_high_l1p3_l2p3, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p3_l2p3.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_l1p3_l2p3.png'), 'png');
    
    figure; helper_tfrclusterplot(prm_beta_high_L1_L2_diff, 0.05, true);
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_L1_L2.svg'), 'svg');
    saveas(gcf, fullfile(rootdir, 'results', 'clusters_prm_beta_high_L1_L2.png'), 'png');
    
    
    % save results to look up p-values later
    fprintf('\n*** Saving results. ***\n');
    
    save(fullfile(rootdir, 'results', 'group_tfr_beta.mat'));
end