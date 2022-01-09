% @Description: Compute group-level theta/delta sources for visual inspection.

function group_roi_theta(subjects, rootdir)
    fprintf('\n*** Collecting data. ***\n');
    
    % load source power data
    allsources_early = {};
    allsources_late = {};
    inc_subjects = {};
    
    for k = 1:size(subjects, 2)
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end
        
        load(fullfile(subjects(k).out, 'subj_source_delta_roi.mat'), 'source_pow_early', 'source_pow_late');
        inc_subjects{end+1} = subjects(k).code;
    
        allsources_early{k} = source_pow_early;
        allsources_late{k} = source_pow_late;
    end
    
    allsources_early = allsources_early(~cellfun('isempty', allsources_early))';
    allsources_late = allsources_late(~cellfun('isempty', allsources_late))';
    
    allsources = {allsources_early, allsources_late};
    allsources_labels = {'Early Period', 'Late Period'};
    
    % load ß-estimate data
    load(fullfile(rootdir, 'processed', 'combined', 'ws_scores.mat'));
    ws_scores = x;
    
    load(fullfile(rootdir, 'processed', 'combined', 'learning_scores.mat'));
    learning_scores = x;
    
    betas = {ws_scores, learning_scores};
    betas_labels = {'Outcome effect', 'Learning effect'};
    
    
    % reshape data as required
    fprintf('\n*** Reshaping data structures. ***\n');
    
    % source power matrices
    % subject x roi x window x condition x repetition x trial
    % ROI:  1 - left mSFG
    %       2 - left PT
    %       3 - right HPC
    %       4 - right pHPC
    %       5 - left ACC
    %       6 - left CN
    % WDW:  1 - early
    %       2 - late
    power = NaN(size(allsources{1}, 1), 6, 2, 4, 4, 20); 
    power_clean = NaN(size(allsources{1}, 1), 6, 2, 4, 4, 20);
    
    % rt matrices
    % subject x condition x repetition x trial
    rts = NaN(size(allsources{1}, 1), 4, 4, 20);
    rts_clean = NaN(size(allsources{1}, 1), 4, 4, 20);
    
    % beta matrices
    % subject x condition x repetition x trial x beta-type x z-dim
    zdim = NaN(size(allsources{1}, 1), 4, 4, 20, 2, 2); 
    
    % condition definitions
    % list x pool
    conditions = [1 1;
                  1 3;
                  2 2;
                  2 3];
    
    % traverse data
    for k = 1:size(allsources{1}, 1)
        % ^ loop over sources
        for m = 1:size(allsources, 2)
            % ^ loop over windows
            for c = 1:size(conditions, 1)
                % ^ loop over conditions
                l = conditions(c,1);
                p = conditions(c,2);
                
                trials = find(allsources{m}{k}.trialinfo(:,6) == p & ...
                              allsources{m}{k}.trialinfo(:,7) == l & ...
                              allsources{m}{k}.trialinfo(:,9) > 0 & ...
                              allsources{m}{k}.trialinfo(:,9) < 3000);
                index = zeros(numel(trials), 1);
        
                for j = 1:numel(trials)
                    index(j) = numel(find(allsources{m}{k}.trialinfo(trials(1:j),2) == allsources{m}{k}.trialinfo(trials(j),2)));
                end
                
                for j = 1:4
                    rts(k, c, j, 1:numel(trials(find(index == j)))) = allsources{m}{k}.trialinfo(trials(find(index == j)), 9);
                    
                    sub = inc_subjects(k);
                    id = allsources{m}{k}.trialinfo(trials(find(index == j)), 2);
                    spkr = allsources{m}{k}.trialinfo(trials(find(index == j)), 3);
                    
                    for n = 1:size(betas, 2)
                        for h = 1:numel(id)
                            hl = find(strcmp(sub, {betas{n}{:,1}}) & ismember({betas{n}{:,2}}, string(id(h))));
                            if numel(hl) > 0
                                zdim(k, c, j, h, n, 1) = mean(str2double(betas{n}{hl(1),8}));
                            end
    
                            hl = find(strcmp(sub, {betas{n}{:,1}}) & ismember({betas{n}{:,3}}, string(spkr(h))));
                            if numel(hl) > 0
                                zdim(k, c, j, h, n, 2) = mean(str2double(betas{n}{hl(1),9}));
                            end
                        end
                    end
                end
        
                for j = 1:size(allsources{m}{k}.pow, 1)
                    for i = 1:4
                        power(k, j, m, c, i, 1:numel(trials(find(index == i)))) = allsources{m}{k}.pow(j, trials(find(index == i)));
                    end
                end
            end
        end
    end
    
    
    % clean data
    fprintf('\n*** Cleaning data. ***\n');
    
    power_clean = power;
    
    for k = 1:size(allsources, 1) % subjects x
        for j = 1:4 % rois x 
            for m = 1:2 % windows x
                for i = 1:4 % conditions x
                    for l = 1:4 % repetitions
                        values = squeeze(power(k, j, m, i, l, :));
                        nan_indices = isnan(values);
                        if nnz(nan_indices) > 0
                            values(nan_indices) = repmat(nanmedian(values), nnz(nan_indices), 1);
                        end
                        out = isoutlier(values);
                        power_clean(k, j, m, i, l, out) = NaN(1, nnz(out));
                    end
                end
            end
        end
    end
    
    
    rts_clean = rts;
    
    for k = 1:size(allsources, 1) % subjects x
        for i = 1:4 % conditions x
            for l = 1:4 % repetitions
                values = squeeze(rts(k, i, l, :));
                nan_indices = isnan(values);
                if nnz(nan_indices) > 0
                    values(nan_indices) = repmat(nanmedian(values), nnz(nan_indices), 1);
                end
                out = isoutlier(values);
                rts_clean(k, i, l, out) = NaN(1, nnz(out));
            end
        end
    end
    
    % average over axes as required
    fprintf('\n*** Averaging over axes. ***\n');
    
    mu_ax1 = 6; % average over trials
    mu_ax2 = 5; % average over repetitions
    
    % block-wise RT, power and repetition setup
    % subject x roi x window x condition x repetition
    rts_clean_match = repmat(reshape(rts_clean, size(power_clean, 1), 1, 1, size(power_clean, 4), size(power_clean, 5), size(power_clean, 6)), 1, 6, 2, 1, 1, 1);
    rt_by_block = nanmean(rts_clean_match, mu_ax1);
    power_by_block = nanmean(power_clean, mu_ax1);
    rep_by_block = ones(size(power_by_block));
    rep_by_block(:,:,:,:,2,:) = 2;
    rep_by_block(:,:,:,:,3,:) = 3;
    rep_by_block(:,:,:,:,4,:) = 4;
    
    % item-wise RT, power and z-dim setup
    % subject x roi x window x condition x item [x beta-type x z-dim]
    rt_by_item = squeeze(nanmean(rts_clean_match, mu_ax2));
    power_by_item = squeeze(nanmean(power_clean, mu_ax2));
    zdim_by_item = squeeze(nanmean(zdim, mu_ax2-2));
    zdim_by_item = repmat(reshape(zdim_by_item, size(zdim_by_item, 1), 1, 1, size(zdim_by_item, 2), size(zdim_by_item, 3), size(zdim_by_item, 4), size(zdim_by_item, 5)), 1, 6, 2, 1, 1, 1, 1);
    
    % create power and rt averages (over repetitions)
    pwravg_items = nanmean(power_by_item, 5);
    rtavg_items = nanmean(rt_by_item, 5);
    
    % setup power contrasts we computed in clusters
    vs_pwrcon = nan([size(pwravg_items, 1:3), 4]);
    vs_pwrcon(:, :, :, 1) = pwravg_items(:, :, :, 1) - pwravg_items(:, :, :, 2);
    vs_pwrcon(:, :, :, 2) = pwravg_items(:, :, :, 3) - pwravg_items(:, :, :, 4);
    vs_pwrcon(:, :, :, 3) = pwravg_items(:, :, :, 1) - pwravg_items(:, :, :, 3);
    vs_pwrcon(:, :, :, 4) = pwravg_items(:, :, :, 2) - pwravg_items(:, :, :, 4);
    
    % setup rt contrasts we computed in clusters
    vs_rtcon = nan([size(pwravg_items, 1:3), 4]);
    vs_rtcon(:, :, :, 1) = rtavg_items(:, :, :, 1) - rtavg_items(:, :, :, 2);
    vs_rtcon(:, :, :, 2) = rtavg_items(:, :, :, 3) - rtavg_items(:, :, :, 4);
    vs_rtcon(:, :, :, 3) = rtavg_items(:, :, :, 1) - rtavg_items(:, :, :, 3);
    vs_rtcon(:, :, :, 4) = rtavg_items(:, :, :, 2) - rtavg_items(:, :, :, 4);
    
    % plot
    fprintf('\n*** Computing and plotting. ***\n');
    
    % setup matrix containing all comparisons of interest
    % these are taken from the significant results of the cluster tests
    % ROI x TOI x COI x COND1 x COND2
    run_comps = [1, 1, 1, 1, 2; % (lvv - lvs): smg (early) x rt
                 5, 2, 1, 1, 2; % (lvv - lvs): acc (late) x rt
                 3, 2, 1, 1, 2; % (lvv - lvs): hpc (late) x rt
                 2, 2, 2, 3, 4; % (hvv - hvs): pt (late) x rt
                 6, 2, 4, 2, 4; % (lvs - hvs): cn (late) x rt
                 4, 2, 4, 2, 4  % (lvs - hvs): phpc (late) x rt
                 ];
    
    % setup labels for power x rt correlations
    % y-axis, title, figure name
    run_labs = {'\Delta Source power SFG (z-score)', 'Low var. (veridical - statistical) \theta', 'corr_lvls_theta_smg';
                '\Delta Source power ACC (z-score)', 'Low var. (veridical - statistical) \delta', 'corr_lvls_delta_acc';
                '\Delta Source power HPC (z-score)', 'Low var. (veridical - statistical) \delta', 'corr_lvls_delta_hpc';
                '\Delta Source power PT (z-score)', 'High var. (veridical - statistical) \delta', 'corr_hvhs_delta_pt';
                '\Delta Source power CN (z-score)', 'Statistical (low var. - high var.) \delta', 'corr_lshs_delta_cn';
                '\Delta Source power PHC (z-score)', 'Statistical (low var. - high var.) \delta', 'corr_lshs_delta_phc'};
    
    % create correlation plots power x rt for all contrasts
    % to see which source contrasts explain the corresponding
    % behavioural contrasts
    for k = 1:size(run_comps, 1)
        kR = run_comps(k, 1);
        kT = run_comps(k, 2);
        kC = run_comps(k, 3);
        
        [f, r, p] = helper_corrplot(vs_rtcon(:, kR, kT, kC), vs_pwrcon(:, kR, kT, kC), [-320, 320], [-0.3, 0.3], '\Delta Reaction time (ms)', run_labs(k, 1), run_labs(k, 2))
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.svg', run_labs{k, 3})), 'svg');
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.png', run_labs{k, 3})), 'png');
    end

    % setup power contrasts (by block!)
    bp_pwrcon = nan(size(power_by_block));
    bp_pwrcon(:, :, :, 1, :) = power_by_block(:, :, :, 1, :) - power_by_block(:, :, :, 2, :);
    bp_pwrcon(:, :, :, 2, :) = power_by_block(:, :, :, 3, :) - power_by_block(:, :, :, 4, :);
    bp_pwrcon(:, :, :, 3, :) = power_by_block(:, :, :, 1, :) - power_by_block(:, :, :, 3, :);
    bp_pwrcon(:, :, :, 4, :) = power_by_block(:, :, :, 2, :) - power_by_block(:, :, :, 4, :);
    
    % compute mean and CI over subjects
    bp_pwrmu = nanmean(power_by_block, 1);
    bp_pwrci = nanstd(power_by_block, 1) ./ sqrt(size(power_by_block, 1));
    
    % setup labels for block-wise comparisons
    % y-axis, title, figure name, legend1, legend2
    run_labs = {'\Delta Source power SFG (z-score)', 'Low var. (veridical - statistical) \theta', 'blocks_lvls_theta_smg', 'Veridical', 'Statistical';
                '\Delta Source power ACC (z-score)', 'Low var. (veridical - statistical) \delta', 'blocks_lvls_delta_acc', 'Veridical', 'Statistical';
                '\Delta Source power HPC (z-score)', 'Low var. (veridical - statistical) \delta', 'blocks_lvls_delta_hpc', 'Veridical', 'Statistical';
                '\Delta Source power PT (z-score)', 'High var. (veridical - statistical) \delta', 'blocks_hvhs_delta_pt', 'Veridical',' Statistical';
                '\Delta Source power CN (z-score)', 'Statistical (low var. - high var.) \delta', 'blocks_hvhs_delta_cn', 'Low var.', 'High var.';
                '\Delta Source power PHC (z-score)', 'Statistical (low var. - high var.) \delta', 'blocks_lshs_delta_phc', 'Low var.', 'High var.'};
    
    % setup alpha
    alpha = 0.05;
    
    % create block-wise comparison plots to look at
    % the evolution of source power across blocks
    % and to get at _where_ exactly they differ. we do
    % this because it stands to reason that there should
    % be a sort of switch-point
    for k = 1:size(run_comps, 1)
        kR = run_comps(k, 1);
        kT = run_comps(k, 2);
        kC = run_comps(k, 3);
        kC1 = run_comps(k, 4);
        kC2 = run_comps(k, 5);
        
        f = figure('Position', [0 0 300 300]); hold on; grid on;
    
        hl = zeros(2, 1);
        cols = ft_colormap('viridis', 2);
        
        hl(1) = boundedline(squeeze(rep_by_block(1, kR, kT, kC1, :)), squeeze(bp_pwrmu(1, kR, kT, kC1, :)), squeeze(bp_pwrci(1, kR, kT, kC1, :)), 's-', 'cmap', cols(1, :), 'alpha', 'transparency', 0.1);
        set(hl(1), 'markerfacecolor', get(hl(1), 'color'), 'markersize', 3, 'linewidth', 2);
        hl(2) = boundedline(squeeze(rep_by_block(1, kR, kT, kC2, :)), squeeze(bp_pwrmu(1, kR, kT, kC2, :)), squeeze(bp_pwrci(1, kR, kT, kC2, :)), 's-', 'cmap', cols(2, :), 'alpha', 'transparency', 0.1);
        set(hl(2), 'markerfacecolor', get(hl(2), 'color'), 'markersize', 3, 'linewidth', 2);
        
        s = 0.1;
        ds = 1 / s;

        x_sig = 1:4;
        y_sig = nan(size(x_sig));

        for j = x_sig
            [~, p] = ttest(bp_pwrcon(:, kR, kT, kC, j));

            if p <= alpha
                y_sig(j) = -0.15;
            end
            
            p_t = 'n.s.';
    
            if p <= alpha / 50
                p_t = '***';
            elseif p <= alpha / 5
                p_t = '**';
            elseif p <= alpha
                p_t = '*';
            end
    
            if p <= alpha
                text(j, -0.17, p_t, 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontName', 'Roboto', 'FontSize', 8, 'FontWeight', 'bold');
            end
        end

        px_sig = 1-s:s:4+s;
        py_sig = nan(size(px_sig));

        for j = x_sig
            if j == max(x_sig)
                break
            end

            if ~isnan(y_sig(x_sig(j)))
                s = (j-1)*ds + 1;
                e = (j-1)*ds + 3;

                if ~isnan(y_sig(x_sig(j+1)))
                    e = j*ds + 3;
                end

                py_sig(s:e) = y_sig(j);
            end
        end

        plot(px_sig, py_sig, 'k-', 'LineWidth', 2)
    
        xlim([0.75, 4.25]);
        xticks([1, 2, 3, 4]);
        ylim([-0.18, 0.18]);
        xlabel('Block (#)');
        ylabel(run_labs(k, 1));
        title(run_labs(k, 2));
        legend(hl, run_labs{k, 4}, run_labs{k, 5});
    
        ax = gca; 
        ax.FontName = 'Roboto'; 
        ax.FontSize = 8;
        
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.svg', run_labs{k, 3})), 'svg');
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.png', run_labs{k, 3})), 'png');
    end
    
    % setup power and zdim contrasts
    zdim_avg = squeeze(nanmean(zdim_by_item, 5));
    zdim_con = nan(size(zdim_avg));
    zdim_con(:, :, :, 1, :, :) = zdim_avg(:, :, :, 1, :, :) - zdim_avg(:, :, :, 2, :, :);
    zdim_con(:, :, :, 2, :, :) = zdim_avg(:, :, :, 3, :, :) - zdim_avg(:, :, :, 4, :, :);
    zdim_con(:, :, :, 3, :, :) = zdim_avg(:, :, :, 1, :, :) - zdim_avg(:, :, :, 3, :, :);
    zdim_con(:, :, :, 4, :, :) = zdim_avg(:, :, :, 2, :, :) - zdim_avg(:, :, :, 4, :, :);

    pwr_avg = nanmean(nanmean(power_clean, 5), 6);
    pwr_con = nan([size(pwr_avg, 1:3), 4]);
    pwr_con(:, :, :, 1) = pwr_avg(:, :, :, 1) - pwr_avg(:, :, :, 2);
    pwr_con(:, :, :, 2) = pwr_avg(:, :, :, 3) - pwr_avg(:, :, :, 4);
    pwr_con(:, :, :, 3) = pwr_avg(:, :, :, 1) - pwr_avg(:, :, :, 3);
    pwr_con(:, :, :, 4) = pwr_avg(:, :, :, 2) - pwr_avg(:, :, :, 4);
    pwr_con = repmat(pwr_con, 1, 1, 1, 1, 2, 2);

    % setup comparisons to run
    % ROI x TOI x COI x POI x ZOI
    run_comps = [1, 2, 1, 1, 1;
                 3, 1, 1, 1, 1;
                 5, 1, 1, 1, 1;
                 2, 2, 2, 1, 1;
                 6, 2, 4, 1, 1;
                 4, 2, 4, 1, 1];
    
    % setup labels for runs
    % x-label, y-label, title, figname
    run_labs = {'\Delta Word effect (z-score)', '\Delta Source power SFG (z-score)', 'Low var. (veridical - statistical) \theta', 'wecorr_lvls_theta_sfg'; 
                '\Delta Word effect (z-score)', '\Delta Source power HPC (z-score)', 'Low var. (veridical - statistical) \delta', 'wecorr_lvls_delta_hpc';
                '\Delta Word effect (z-score)', '\Delta Source power ACC (z-score)', 'Low var. (veridical - statistical) \delta', 'wecorr_lvls_delta_acc';
                '\Delta Word effect (z-score)', '\Delta Source power PT (z-score)', 'High var. (veridical - statistical) \delta', 'wecorr_hvhs_delta_pt';
                '\Delta Word effect (z-score)', '\Delta Source power CN (z-score)', 'Statistical (low var. - high var.) \delta', 'wecorr_lshs_delta_cn';
                '\Delta Word effect (z-score)', '\Delta Source power PHC (z-score)', 'Statistical (low var. - high var.) \delta', 'wecorr_lshs_delta_phc'};
    
    % setup correlations and plots to look at whether
    % the word effects we extracted from the behavioural
    % data (see run_evo.R for modelling details) correspond
    % with MEG power in the relevant contrasts; this is
    % an interesting sanity check for us - not sure how
    % relevant this really is in terms of outcomes - it
    % should largely reflect the power x RT correlations
    for k = 1:size(run_comps, 1)
        tR = run_comps(k, 1);
        tT = run_comps(k, 2);
        tC = run_comps(k, 3);
        tP = run_comps(k, 4);
        tZ = run_comps(k, 5);

        indx = ~isnan(zdim_con(:, tR, tT, tC, tP, tZ)) & ~isnan(pwr_con(:, tR, tT, tC, tP, tZ));
        this_z = zdim_con(:, tR, tT, tC, tP, tZ);
        this_z = this_z(indx);
        this_pwr = pwr_con(:, tR, tT, tC, tP, tZ);
        this_pwr = this_pwr(indx);

        minmaxz = max(abs([min(this_z), max(this_z)])) * 1.1;
        minmaxp = max(abs([min(this_pwr), max(this_pwr)])) * 1.1;

        [f, r, p] = helper_corrplot(this_z(:), this_pwr(:), [-minmaxz minmaxz], [-minmaxp minmaxp], run_labs{k,1}, run_labs{k,2}, run_labs{k,3})
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.svg', run_labs{k,4})), 'svg');
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.png', run_labs{k,4})), 'png');
    end
    
    % collect data into new structures for MT analyses
    fprintf('\n*** Collecting MT data structures. ***\n');
    
    pwr_items = nan([size(power_clean, 1:4), 20, 4]);
    lbl_items = nan([size(power_clean, 1:4), 20]);
    pwr_speakers = nan([size(power_clean, 1:4), 4, 20]);
    lbl_speakers = nan([size(power_clean, 1:4), 4]);
    
    for k = 1:size(allsources{1}, 1)
        % ^ loop over sources
        for m = 1:size(allsources, 2)
            % ^ loop over windows
            for c = 1:size(conditions, 1)
                % ^ loop over conditions
                l = conditions(c,1);
                p = conditions(c,2);
                
                trials = find(allsources{m}{k}.trialinfo(:,6) == p & ...
                              allsources{m}{k}.trialinfo(:,7) == l);
                ids = allsources{m}{k}.trialinfo(trials, 2);
                spkrs = allsources{m}{k}.trialinfo(trials, 3);
                
                lbl_items(k, :, m, c, :) = repmat(reshape(unique(ids), 1, 1, 1, 1, numel(unique(ids))), 1, size(lbl_items, 2), 1, 1, 1);
                lbl_speakers(k, :, m, c, :) = repmat(reshape(unique(spkrs), 1, 1, 1, 1, numel(unique(spkrs))), 1, size(lbl_speakers, 2), 1, 1, 1);
                
                for j = 1:size(allsources{m}{k}.pow, 1)
                    % ^ loop over ROIs
                    for h = 1:size(trials, 1)
                        pwr_items(k, j, m, c, find(unique(ids) == ids(h)), ceil(trials(h) / 80)) = allsources{m}{k}.pow(j,trials(h));
                        pwr_speakers(k, j, m, c, find(unique(spkrs) == spkrs(h)), find(isnan(pwr_speakers(k, j, m, c, find(unique(spkrs) == spkrs(h)), :)), 1, 'first')) = allsources{m}{k}.pow(j,trials(h));
                    end
                end
            end
        end
    end
    
    % make easily readable averages matrix
    mt_pwr = nan([size(pwr_items, 1:4), 80, 2]);
    
    pwr_items_avg = nanmean(pwr_items, 6);
    pwr_speakers_avg = nanmean(pwr_speakers, 6);
    
    for k = 1:size(allsources{1}, 1)
        % ^ loop over all sources
        for c = 1:size(conditions, 1)
            % ^ loop over all conditions
            l = conditions(c,1);
            p = conditions(c,2);
            
            trials = find(allsources{1}{k}.trialinfo(:,6) == p & ...
                          allsources{1}{k}.trialinfo(:,7) == l);
            ids = allsources{1}{k}.trialinfo(trials, 2);
            uids = unique(ids);
            spkrs = allsources{1}{k}.trialinfo(trials, 3);
            uspkrs = unique(spkrs);
            
            for n = 1:size(trials, 1)
                mt_pwr(k, :, :, c, n, 1) = pwr_items_avg(k, :, :, c, find(uids == ids(n)));
                mt_pwr(k, :, :, c, n, 2) = pwr_speakers_avg(k, :, :, c, find(uspkrs == spkrs(n)));
            end
        end
    end


    fprintf('\n*** Computing and plotting. ***\n');
    
    % subset matrix by word and speaker dimension
    mt_pwr_word = squeeze(mt_pwr(:, :, :, :, :, 1));
    mt_pwr_spkr = squeeze(mt_pwr(:, :, :, :, :, 2));

    % setup comparisons to run
    % ROI x TOI x COIw x COIs
    run_comps = {1, 1, 1:2, 1:2;
                 5, 2, 1:2, 1:2;
                 3, 2, 1:2, 1:2;
                 2, 2, 1:2, 1:2;
                 6, 2, 1:2, 1:2;
                 4, 2, 1:2, 1:2;
                 1, 1, 3:4, 3:4;
                 5, 2, 3:4, 3:4;
                 3, 2, 3:4, 3:4;
                 2, 2, 3:4, 3:4;
                 6, 2, 3:4, 3:4;
                 4, 2, 3:4, 3:4;
                 };

    % setup labels for comparisons
    % x-label, y-label, title, figname
    run_labs = {'Source power SFG by speaker (z-score)', 'Source power SFG by word (z-score)', 'Low-variability training \theta', 'mtmeg_sfg_low';
                'Source power ACC by speaker (z-score)', 'Source power ACC by word (z-score)', 'Low-variability training \delta', 'mtmeg_acc_low';
                'Source power HPC by speaker (z-score)', 'Source power HPC by word (z-score)', 'Low-variability training \delta', 'mtmeg_hpc_low';
                'Source power PT by speaker (z-score)', 'Source power PT by word (z-score)', 'Low-variability training \delta', 'mtmeg_pt_low';
                'Source power CN by speaker (z-score)', 'Source power CN by word (z-score)', 'Low-variability training \delta', 'mtmeg_cn_low';
                'Source power PHC by speaker (z-score)', 'Source power PHC by word (z-score)', 'Low-variability training \delta', 'mtmeg_phc_low';
                'Source power SFG by speaker (z-score)', 'Source power SFG by word (z-score)', 'High-variability training \theta', 'mtmeg_sfg_high';
                'Source power ACC by speaker (z-score)', 'Source power ACC by word (z-score)', 'High-variability training \delta', 'mtmeg_acc_high';
                'Source power HPC by speaker (z-score)', 'Source power HPC by word (z-score)', 'High-variability training \delta', 'mtmeg_hpc_high';
                'Source power PT by speaker (z-score)', 'Source power PT by word (z-score)', 'High-variability training \delta', 'mtmeg_pt_high';
                'Source power CN by speaker (z-score)', 'Source power CN by word (z-score)', 'High-variability training \delta', 'mtmeg_cn_high';
                'Source power PHC by speaker (z-score)', 'Source power PHC by word (z-score)', 'High-variability training \delta', 'mtmeg_phc_high'};
    
    % compute and plot correlations between word- and speaker-
    % -averaged power to see if we see something similar to the
    % behavioural case, although it is really quite unlikely
    % we should be able to produce the exact same result - 
    % instead, it should probably be a similar result but
    % with the correlation being almost certainly positive
    for k = 1:size(run_comps, 1)
        tR = run_comps{k, 1};
        tT = run_comps{k, 2};
        tCw = run_comps{k, 3};
        tCs = run_comps{k, 4};

        indxw = false(size(mt_pwr, 1:5));
        indxw(:, tR, tT, tCw, :) = ~isnan(mt_pwr(:, tR, tT, tCw, :, 1)) & ~isnan(mt_pwr(:, tR, tT, tCs, :, 2));
        indxs = false(size(mt_pwr, 1:5));
        indxs(:, tR, tT, tCs, :) = ~isnan(mt_pwr(:, tR, tT, tCw, :, 1)) & ~isnan(mt_pwr(:, tR, tT, tCs, :, 2));

        [f, r, p] = helper_corrplot(mt_pwr_spkr(indxs), mt_pwr_word(indxw), [-1.75 1.75], [-1.75 1.75], run_labs{k,1}, run_labs{k,2}, run_labs{k,3});
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.svg', run_labs{k,4})), 'svg');
        saveas(f, fullfile(rootdir, 'results', sprintf('%s.png', run_labs{k,4})), 'png');
    end
    
    % save
    fprintf('\n*** Saving workspace. ***\n');
    clear f;
    save(fullfile(rootdir, 'results', 'group_roi_delta.mat'));
end