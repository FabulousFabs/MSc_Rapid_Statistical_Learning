% @Description: Runs all group-level analyses.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /home/common/matlab/fieldtrip/qsub;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

subjects = helper_datainfo(rootdir);

%% compute overall TFRs that we use for visual inspection
group_tfr(subjects, rootdir);

% please note that at this stage the final TOI/FOI selection has to be done
% such that the scripts afterwards can be run only once. this was done
% explicitly in the following scripts for ease-of-use (to avoid long-winded
% functions computing any dynamically specified combinations)

%% compute clusters for selected TOIs/FOIs
group_tfr_theta(subjects, rootdir);
group_tfr_beta(subjects, rootdir);

% please note that at this stage the final source localisation TOI/FOIs
% should be taken from the results of the cluster-based permutation tests
% that were run in this step - again, for ease-of-use these will be
% hardcoded, albeit its ugliness; note that this also affects the use of
% qsub_run_subject_source!
% Please run run_subject_qsub_source.m before proceeding.

%% compute sources for selected TOIs/FOIs
group_source_theta(subjects, rootdir);
group_source_beta(subjects, rootdir);

%%
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
                        hl = find(strcmp(sub, {betas{n}{:,1}}) & ismember({betas{n}{:,2}}, string(id(h))) & ismember({betas{n}{:,3}}, string(spkr(h))));
                        if numel(hl) > 0
                            zdim(k, c, j, h, n, 1) = str2double(betas{n}{hl,8});
                            zdim(k, c, j, h, n, 2) = str2double(betas{n}{hl,9});
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

%%
fprintf('\n*** Computing correlations. ***\n');

indx = false(size(power_by_block));
indx(:, 3, 2, 2:2:4, :) = ~isnan(rep_by_block(:, 3, 2, 2:2:4, :)) & ~isnan(power_by_block(:, 3, 2, 2:2:4, :));
[f, r, p] = helper_corrplot(rep_by_block(indx), power_by_block(indx), [0.75, 4.25], [-1.5, 1.5], 'Block', 'HPC', '')


%%

indx = false(size(power_by_item));
indx(:, 4, 2, :, :) = ~isnan(rt_by_item(:, 4, 2, :, :)) & ~isnan(power_by_item(:, 4, 2, :, :));
[f, r, p] = helper_corrplot(rt_by_item(indx), power_by_item(indx), [0.0, 3000.0], [-1.5, 1.5], 'Block', 'HPC', '')

%%
indx = false(size(power_by_item));
indx(:, 4, 2, 2:2:4, :) = ~isnan(rt_by_item(:, 4, 2, 2:2:4, :)) & ~isnan(power_by_item(:, 4, 2, 2:2:4, :));
[f, r, p] = helper_corrplot(rt_by_item(indx), power_by_item(indx), [0.0, 3000.0], [-1.5, 1.5], 'Block', 'HPC', '')


%%
%powertest = power_clean
%rttest = squeeze(nanmean(rt_by_item, 5));

%indx = false(size(power_clean));
%indx(:, 3, 2, :) = ~isnan(rts_clean(:, :, :, :)) & ~isnan(power_clean(:, 3, 2, :, :, :))
powertest = power_clean(:, 3, 2, 2:2:4, :, :);
rttest = rts_clean(:, 2:2:4, :, :);
powertest = powertest(:);
rttest = rttest(:);
[f, r, p] = helper_corrplot(rttest, powertest, [0, 3000], [-2, 2], 'RT', 'HPC', '')

%indx = false(size(rep_by_block));
%indx(:, 3, 2, 2:2:4, :) = ~isnan(rep_by_block(:, 3, 2, 2:2:4, :)) & ~isnan(power_by_block(:, 3, 2, 2:2:4, :));
%[f, r, p] = helper_corrplot(rep_by_block(indx), power_by_block(indx), [0.75, 4.25], [-1, 1], 'Block no.', 'Hippocampal source power (z-score)', '');
%r
%p


%%
[R, P] = corrcoef(power_by_block(:, 4, 2, :, :), rep_by_block(:, 4, 2, :, :), 'rows', 'complete')

%indx = false(size(rep_by_block));
%indx(:, 1, 1, :, :) = ~isnan(rep_by_block(:, 1, 1, :, :)) & ~isnan(rt_by_block(:, 1, 1, :, :));
%[f, r, p] = helper_corrplot(rep_by_block(indx), rt_by_block(indx), [0.75, 4.25], [0, 3000], 'Block no.', 'Reaction time (ms)', '');







%%
zdim_word = repmat(reshape(zdim_word, size(power_clean, 1), 1, size(power_clean, 3), size(power_clean, 4), size(power_clean, 5)), 1, 6, 1, 1, 1);
zdim_word_mean = nanmean(zdim_word, mu_ax2);
zdim_spkr = squeeze(zdim(:, :, :, :, 2));
zdim_spkr = repmat(reshape(zdim_spkr, size(power_clean, 1), 1, size(power_clean, 3), size(power_clean, 4), size(power_clean, 5)), 1, 6, 1, 1, 1);
zdim_spkr_mean = nanmean(zdim_spkr, mu_ax2);

repetitions = ones(size(power_clean_mean));
repetitions(:,:,:,2,:) = 2;
repetitions(:,:,:,3,:) = 3;
repetitions(:,:,:,4,:) = 4;

%%
fprintf('\n*** Modelling and plotting. ***\n');

ROIs = 1:4;
ROIs_labels = {'lmSFG source power (z-score)', 'lPT source power (z-score)', 'rHPC source power (z-score)', 'rPHPC source power (z-score)'};

POIs = {zdim_word_mean, zdim_spkr_mean};
POIs_labels = {'Word learning (z-score)', 'Speaker learning (z-score)'};

COIs = {1:4, 1:2:4, 2:2:4, 1:2, 3:4, 1, 2, 3, 4};
COIs_labels = {'All conditions', 'Veridical conditions', 'Statistical conditions', 'Low-variability training', 'High-variability training', 'Veridical conditions LV', 'Statistical conditions LV', 'Veridical conditions HV', 'Statistical conditions HV'};

for i = 1:numel(ROIs)
    % iterate over ROIs

    for j = 1:numel(POIs)
        % iterate over predictors of interest

        for k = 1:numel(COIs)
            % iterate over conditions of interest

            indx = false(size(power_clean_mean2));
            indx(:, ROIs(i), COIs{k}, :) = ~isnan(power_clean_mean2(:, ROIs(i), COIs{k}, :)) & ~isnan(POIs{j}(:, ROIs(i), COIs{k}, :));
            
            if numel(POIs{j}(indx)) == 0
                continue
            end

            f = figure('visible', 'off'); hold on
            scatter(POIs{j}(indx), power_clean_mean2(indx), 10, POIs{j}(indx) .* power_clean_mean2(indx), '.');
            ft_colormap('inferno', 512);
            xlim([-4 4]);
            ylim([-1 1]);
            title(COIs_labels{k});
            mdl = fitlm(POIs{j}(indx), power_clean_mean2(indx));
            xpred = linspace(min(POIs{j}(indx)), max(POIs{j}(indx)), 200)';
            [ypred, yci] = predict(mdl, xpred);
            h = fill_between(xpred, yci(:, 1), yci(:, 2));
            h.EdgeColor = 'none';
            h.FaceColor = [0 0 0];
            h.FaceAlpha = 0.2;
            plot(xpred, ypred, 'k-');
            [R, P] = corrcoef(power_clean_mean2(indx), POIs{j}(indx), 'rows', 'complete');
            text(3, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
            text(3, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
            xlabel(POIs_labels{j});
            ylabel(ROIs_labels{i});

            saveas(f, fullfile(rootdir, 'results', outsub, allsources_label, sprintf('%d_%d_%d.png', i, j, k)));
        end
    end
end


%%
[R, P] = corrcoef(power_clean_mean(:, 3:4, :, :), repetitions(:, 3:4, :, :), 'rows', 'complete')

%%
[R, P] = corrcoef(power_clean_mean(:, 3:4, 1, :), rts_clean_mean(:, 3:4, 1, :), 'rows', 'complete')

%%
[R, P] = corrcoef(power_clean_mean2(:, 6, 1:3, :, :), zdim_spkr_mean(:, 6, 1:3, :, :), 'rows', 'complete')

%%
rep = ones(size(power_clean));
rep(:,:,:,2,:) = 2;
rep(:,:,:,3,:) = 3;
rep(:,:,:,4,:) = 4;
[R, P] = corrcoef(power_clean(:, 3, :, :), rep(:, 3, :, :), 'rows', 'complete')

%%

indx1 = false(size(power_clean_mean));
indx1(:, 3, 2:2:4, :) = ~isnan(power_clean_mean(:, 3, 2:2:4, :)) & ~isnan(rts_clean_mean(:, 3, 2:2:4, :));
indx2 = false(size(power_clean_mean));
indx2(:, 3, 1:2:4, :) = ~isnan(power_clean_mean(:, 3, 1:2:4, :)) & ~isnan(rts_clean_mean(:, 3, 1:2:4, :));
indx3 = false(size(power_clean_mean));
indx3(:, 3, :, :) = ~isnan(power_clean_mean(:, 3, :, :)) & ~isnan(rts_clean_mean(:, 3, :, :));
indx4 = false(size(power_clean_mean));
indx4(:, 3, 2, :) = ~isnan(power_clean_mean(:, 3, 2, :)) & ~isnan(rts_clean_mean(:, 3, 2, :));
indx5 = false(size(power_clean_mean));
indx5(:, 3, 4, :) = ~isnan(power_clean_mean(:, 3, 4, :)) & ~isnan(rts_clean_mean(:, 3, 4, :));
indx6 = false(size(power_clean_mean));
indx6(:, 3, 4, :) = ~isnan(power_clean_mean(:, 3, 1, :)) & ~isnan(rts_clean_mean(:, 3, 1, :));
indx7 = false(size(power_clean_mean));
indx7(:, 3, 4, :) = ~isnan(power_clean_mean(:, 3, 3, :)) & ~isnan(rts_clean_mean(:, 3, 3, :));

indx8 = false(size(power_clean_mean2));
indx8(:, 3, :, :) = ~isnan(power_clean_mean2(:, 3, :, :)) & ~isnan(zdim_word_mean(:, 3, :, :)); % word learning x hpc
indx9 = false(size(power_clean_mean2));
indx9(:, 3, :, :) = ~isnan(power_clean_mean2(:, 3, :, :)) & ~isnan(zdim_spkr_mean(:, 3, :, :)); % speaker learning x hpc

indx10 = false(size(power_clean_mean2));
indx10(:, 3, 2:2:4, :) = ~isnan(power_clean_mean2(:, 3, 2:2:4, :)) & ~isnan(zdim_word_mean(:, 3, 2:2:4, :)); % word learning x hpc (statistical conditions)
indx11 = false(size(power_clean_mean2));
indx11(:, 3, 2:2:4, :) = ~isnan(power_clean_mean2(:, 3, 2:2:4, :)) & ~isnan(zdim_spkr_mean(:, 3, 2:2:4, :)); % speaker learning x hpc (statistical conditions)

indx12 = false(size(power_clean_mean2));
indx12(:, 3, 1:2:4, :) = ~isnan(power_clean_mean2(:, 3, 1:2:4, :)) & ~isnan(zdim_word_mean(:, 3, 1:2:4, :)); % word learning x hpc (veridical conditions)
indx13 = false(size(power_clean_mean2));
indx13(:, 3, 1:2:4, :) = ~isnan(power_clean_mean2(:, 3, 1:2:4, :)) & ~isnan(zdim_spkr_mean(:, 3, 1:2:4, :)); % speaker learning x hpc (veridical conditions)

cond = 2:2:4;
reg = 1;
which = zdim_word_mean;
indx14 = false(size(power_clean_mean2));
indx14(:, reg, cond, :) = ~isnan(power_clean_mean2(:, reg, cond, :)) & ~isnan(which(:, reg, cond, :));
[R, P] = corrcoef(power_clean_mean2(indx14), which(indx14), 'rows', 'complete')

scatter(which(indx14), power_clean_mean2(indx14), '.');

%%
f5 = figure; hold on
scatter(zdim_word_mean(indx8), power_clean_mean2(indx8), 10, zdim_word_mean(indx8) .* power_clean_mean2(indx8), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Overall');
mdl8 = fitlm(zdim_word_mean(indx8), power_clean_mean2(indx8));
xpred8 = linspace(min(zdim_word_mean(indx8)), max(zdim_word_mean(indx8)), 200)';
[ypred8, yci8] = predict(mdl8, xpred8);
h8 = fill_between(xpred8, yci8(:, 1), yci8(:, 2));
h8.EdgeColor = 'none';
h8.FaceColor = [0 0 0];
h8.FaceAlpha = 0.2;
plot(xpred8, ypred8, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx8), zdim_word_mean(indx8), 'rows', 'complete');
text(3, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(3, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Word learning (z-score)');
ylabel('Hippocampal source power (z-score)');

f6 = figure;
subplot(1, 2, 1); hold on
scatter(zdim_word_mean(indx10), power_clean_mean2(indx10), 10, zdim_word_mean(indx10) .* power_clean_mean2(indx10), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Statistical word conditions');
mdl10 = fitlm(zdim_word_mean(indx10), power_clean_mean2(indx10));
xpred10 = linspace(min(zdim_word_mean(indx10)), max(zdim_word_mean(indx10)), 200)';
[ypred10, yci10] = predict(mdl10, xpred10);
h10 = fill_between(xpred10, yci10(:, 1), yci10(:, 2));
h10.EdgeColor = 'none';
h10.FaceColor = [0 0 0];
h10.FaceAlpha = 0.2;
plot(xpred10, ypred10, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx10), zdim_word_mean(indx10), 'rows', 'complete');
text(2, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Word learning (z-score)');
ylabel('Hippocampal source power (z-score)');

subplot(1, 2, 2); hold on
scatter(zdim_word_mean(indx12), power_clean_mean2(indx12), 10, zdim_word_mean(indx12) .* power_clean_mean2(indx12), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Veridical episodic conditions');
mdl12 = fitlm(zdim_word_mean(indx12), power_clean_mean2(indx12));
xpred12 = linspace(min(zdim_word_mean(indx12)), max(zdim_word_mean(indx12)), 200)';
[ypred12, yci12] = predict(mdl12, xpred12);
h12 = fill_between(xpred12, yci12(:, 1), yci12(:, 2));
h12.EdgeColor = 'none';
h12.FaceColor = [0 0 0];
h12.FaceAlpha = 0.2;
plot(xpred12, ypred12, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx12), zdim_word_mean(indx12), 'rows', 'complete');
text(2, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Word learning (z-score)');
ylabel('Hippocampal source power (z-score)');

f7 = figure; hold on
scatter(zdim_spkr_mean(indx9), power_clean_mean2(indx9), 10, zdim_spkr_mean(indx9) .* power_clean_mean2(indx9), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Overall');
mdl9 = fitlm(zdim_spkr_mean(indx9), power_clean_mean2(indx9));
xpred9 = linspace(min(zdim_spkr_mean(indx8)), max(zdim_spkr_mean(indx9)), 200)';
[ypred9, yci9] = predict(mdl9, xpred9);
h9 = fill_between(xpred9, yci9(:, 1), yci9(:, 2));
h9.EdgeColor = 'none';
h9.FaceColor = [0 0 0];
h9.FaceAlpha = 0.2;
plot(xpred9, ypred9, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx9), zdim_spkr_mean(indx9), 'rows', 'complete');
text(3, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(3, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Speaker learning (z-score)');
ylabel('Hippocampal source power (z-score)');

f8 = figure;
subplot(1, 2, 1); hold on
scatter(zdim_spkr_mean(indx11), power_clean_mean2(indx11), 10, zdim_spkr_mean(indx11) .* power_clean_mean2(indx11), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Statistical word conditions');
mdl11 = fitlm(zdim_spkr_mean(indx11), power_clean_mean2(indx11));
xpred11 = linspace(min(zdim_spkr_mean(indx11)), max(zdim_spkr_mean(indx11)), 200)';
[ypred11, yci11] = predict(mdl11, xpred11);
h11 = fill_between(xpred11, yci11(:, 1), yci11(:, 2));
h11.EdgeColor = 'none';
h11.FaceColor = [0 0 0];
h11.FaceAlpha = 0.2;
plot(xpred11, ypred11, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx11), zdim_spkr_mean(indx11), 'rows', 'complete');
text(2, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Speaker learning (z-score)');
ylabel('Hippocampal source power (z-score)');

subplot(1, 2, 2); hold on
scatter(zdim_spkr_mean(indx13), power_clean_mean2(indx13), 10, zdim_spkr_mean(indx13) .* power_clean_mean2(indx13), '.');
ft_colormap('inferno', 512);
xlim([-4 4]);
ylim([-1 1]);
title('Veridical episodic conditions');
mdl13 = fitlm(zdim_spkr_mean(indx13), power_clean_mean2(indx13));
xpred13 = linspace(min(zdim_spkr_mean(indx13)), max(zdim_spkr_mean(indx13)), 200)';
[ypred13, yci13] = predict(mdl13, xpred13);
h13 = fill_between(xpred13, yci13(:, 1), yci13(:, 2));
h13.EdgeColor = 'none';
h13.FaceColor = [0 0 0];
h13.FaceAlpha = 0.2;
plot(xpred13, ypred13, 'k-');
[R, P] = corrcoef(power_clean_mean2(indx13), zdim_spkr_mean(indx13), 'rows', 'complete');
text(2, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Speaker learning (z-score)');
ylabel('Hippocampal source power (z-score)');
%%

f1 = figure;

subplot(1, 2, 1); hold on
scatter(rts_clean_mean(indx1), power_clean_mean(indx1), 10, rts_clean_mean(indx1) .* power_clean_mean(indx1), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('Statistical word conditions');
mdl1 = fitlm(rts_clean_mean(indx1), power_clean_mean(indx1));
xpred1 = linspace(min(rts_clean_mean(indx1)), max(rts_clean_mean(indx1)), 200)';
[ypred1, yci1] = predict(mdl1, xpred1);
h1 = fill_between(xpred1, yci1(:, 1), yci1(:, 2));
h1.EdgeColor = 'none';
h1.FaceColor = [0 0 0];
h1.FaceAlpha = 0.2;
plot(xpred1, ypred1, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 2:2:4, :, :), 5), nanmean(rts_clean(:, 2:2:4, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

subplot(1, 2, 2); hold on
scatter(rts_clean_mean(indx2), power_clean_mean(indx2), 10, rts_clean_mean(indx2) .* power_clean_mean(indx2), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('Veridical episodic conditions');
mdl2 = fitlm(rts_clean_mean(indx2), power_clean_mean(indx2));
xpred2 = linspace(min(rts_clean_mean(indx2)), max(rts_clean_mean(indx2)), 200)';
[ypred2, yci2] = predict(mdl2, xpred2);
h2 = fill_between(xpred2, yci2(:, 1), yci2(:, 2));
h2.EdgeColor = 'none';
h2.FaceColor = [0 0 0];
h2.FaceAlpha = 0.2;
plot(xpred2, ypred2, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 1:2:4, :, :), 5), nanmean(rts_clean(:, 1:2:4, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p = %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

%%
saveas(f1, fullfile(rootdir, 'results', 'hpc_by_rt.png'), 'png');
saveas(f1, fullfile(rootdir, 'results', 'hpc_by_rt.svg'), 'svg');

%%
f2 = figure; hold on

scatter(rts_clean_mean(indx3), power_clean_mean(indx3), 10, rts_clean_mean(indx3) .* power_clean_mean(indx3), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('All conditions');
mdl3 = fitlm(rts_clean_mean(indx3), power_clean_mean(indx3));
xpred3 = linspace(min(rts_clean_mean(indx3)), max(rts_clean_mean(indx3)), 200)';
[ypred3, yci3] = predict(mdl3, xpred3);
h3 = fill_between(xpred3, yci3(:, 1), yci3(:, 2));
h3.EdgeColor = 'none';
h3.FaceColor = [0 0 0];
h3.FaceAlpha = 0.2;
plot(xpred3, ypred3, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, :, :, :), 5), nanmean(rts_clean(:, :, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

saveas(f2, fullfile(rootdir, 'results', 'hpc_by_rt2.png'), 'png');
saveas(f2, fullfile(rootdir, 'results', 'hpc_by_rt2.svg'), 'svg');

f3 = figure;

subplot(1, 2, 1); hold on
scatter(rts_clean_mean(indx4), power_clean_mean(indx4), 10, rts_clean_mean(indx4) .* power_clean_mean(indx4), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('Low-variability stat.');
mdl4 = fitlm(rts_clean_mean(indx4), power_clean_mean(indx4));
xpred4 = linspace(min(rts_clean_mean(indx4)), max(rts_clean_mean(indx4)), 200)';
[ypred4, yci4] = predict(mdl4, xpred4);
h4 = fill_between(xpred4, yci4(:, 1), yci4(:, 2));
h4.EdgeColor = 'none';
h4.FaceColor = [0 0 0];
h4.FaceAlpha = 0.2;
plot(xpred4, ypred4, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 2, :, :), 5), nanmean(rts_clean(:, 2, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p = %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

subplot(1, 2, 2); hold on
scatter(rts_clean_mean(indx5), power_clean_mean(indx5), 10, rts_clean_mean(indx5) .* power_clean_mean(indx5), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('High-variability stat.');
mdl5 = fitlm(rts_clean_mean(indx5), power_clean_mean(indx5));
xpred5 = linspace(min(rts_clean_mean(indx5)), max(rts_clean_mean(indx5)), 200)';
[ypred5, yci5] = predict(mdl5, xpred5);
h5 = fill_between(xpred5, yci5(:, 1), yci5(:, 2));
h5.EdgeColor = 'none';
h5.FaceColor = [0 0 0];
h5.FaceAlpha = 0.2;
plot(xpred5, ypred5, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 4, :, :), 5), nanmean(rts_clean(:, 4, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p = %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

saveas(f3, fullfile(rootdir, 'results', 'hpc_by_rt3.png'), 'png');
saveas(f3, fullfile(rootdir, 'results', 'hpc_by_rt3.svg'), 'svg');

f4 = figure;

subplot(1, 2, 1); hold on
scatter(rts_clean_mean(indx6), power_clean_mean(indx6), 10, rts_clean_mean(indx6) .* power_clean_mean(indx6), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('Low-variability ver.');
mdl6 = fitlm(rts_clean_mean(indx6), power_clean_mean(indx6));
xpred6 = linspace(min(rts_clean_mean(indx6)), max(rts_clean_mean(indx6)), 200)';
[ypred6, yci6] = predict(mdl6, xpred6);
h6 = fill_between(xpred6, yci6(:, 1), yci6(:, 2));
h6.EdgeColor = 'none';
h6.FaceColor = [0 0 0];
h6.FaceAlpha = 0.2;
plot(xpred6, ypred6, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 1, :, :), 5), nanmean(rts_clean(:, 1, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p = %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

subplot(1, 2, 2); hold on
scatter(rts_clean_mean(indx7), power_clean_mean(indx7), 10, rts_clean_mean(indx7) .* power_clean_mean(indx7), '.');
ft_colormap('inferno', 512);
xlim([0 3000]);
ylim([-1 1]);
title('High-variability ver.');
mdl7 = fitlm(rts_clean_mean(indx7), power_clean_mean(indx7));
xpred7 = linspace(min(rts_clean_mean(indx7)), max(rts_clean_mean(indx7)), 200)';
[ypred7, yci7] = predict(mdl7, xpred7);
h7 = fill_between(xpred7, yci7(:, 1), yci7(:, 2));
h7.EdgeColor = 'none';
h7.FaceColor = [0 0 0];
h7.FaceAlpha = 0.2;
plot(xpred7, ypred7, 'k-');
[R, P] = corrcoef(nanmean(power_clean(:, 3, 3, :, :), 5), nanmean(rts_clean(:, 3, :, :), 4), 'rows', 'complete');
text(2400, 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
text(2400, 0.8, sprintf('p = %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
xlabel('Reaction time (ms)');
ylabel('Hippocampal source power (z-score)');

saveas(f4, fullfile(rootdir, 'results', 'hpc_by_rt4.png'), 'png');
saveas(f4, fullfile(rootdir, 'results', 'hpc_by_rt4.svg'), 'svg');

%%



%%
[R_stat, P_stat] = corrcoef(nanmean(power_clean(:, 1, 2:2:4, :, :), 5), nanmean(rts_clean(:, 2:2:4, :, :), 4), 'rows', 'complete')
[R_veri, P_veri] = corrcoef(nanmean(power_clean(:, 1, 1:2:4, :, :), 5), nanmean(rts_clean(:, 1:2:4, :, :), 4), 'rows', 'complete')
[R_l1, P_l1] = corrcoef(nanmean(power_clean(:, 1, 1:2, :, :), 5), nanmean(rts_clean(:, 1:2, :, :), 4), 'rows', 'complete')
[R_l2, P_l2] = corrcoef(nanmean(power_clean(:, 1, 3:4, :, :), 5), nanmean(rts_clean(:, 3:4, :, :), 4), 'rows', 'complete')
[R_all, P_all] = corrcoef(nanmean(power_clean(:, 1, :, :, :), 5), nanmean(rts_clean(:, :, :, :), 4), 'rows', 'complete')
[R_l1p1, P_l1p1] = corrcoef(nanmean(power_clean(:, 1, 1, :, :), 5), nanmean(rts_clean(:, 1, :, :), 4), 'rows', 'complete')
[R_l1p3, P_l1p3] = corrcoef(nanmean(power_clean(:, 1, 2, :, :), 5), nanmean(rts_clean(:, 2, :, :), 4), 'rows', 'complete')
[R_l2p2, P_l2p2] = corrcoef(nanmean(power_clean(:, 1, 3, :, :), 5), nanmean(rts_clean(:, 3, :, :), 4), 'rows', 'complete')
[R_l2p3, P_l2p3] = corrcoef(nanmean(power_clean(:, 1, 4, :, :), 5), nanmean(rts_clean(:, 4, :, :), 4), 'rows', 'complete')

%%
[R, P] = corrcoef(power_clean(:, 1, 3, :, :), repetitions(:, 1, 3, :, :), 'rows', 'complete')
[R, P] = corrcoef(power_clean(:, 1, 4, :, :), repetitions(:, 1, 4, :, :), 'rows', 'complete')


%%
[msfg_R, msfg_P] = corrcoef(power_clean(:, 1, :, :, :), rts_clean(:, :, :, :), 'rows', 'complete')
[it_R, it_P] = corrcoef(power_clean(:, 2, :, :, :), rts_clean(:, :, :, :), 'rows', 'complete')
[hpc_R, hpc_P] = corrcoef(power_clean(:, 3, :, :, :), rts_clean(:, :, :, :), 'rows', 'complete')
[phpc_R, phpc_P] = corrcoef(power_clean(:, 4, :, :, :), rts_clean(:, :, :, :), 'rows', 'complete')

%%


