% @Description: Prepare MEG data for modelling.
%
% INPUTS:
%   pwdir   - Present working directory (for python)
%   outdir  - Directory for exports

function prep_MEG(pwdir, outdir)
    fprintf('\n*** Starting preprocessing of behavioural data from MEG task. ***\n');

    % run external aggregation
    fprintf('\n*** Collecting data. ***\n');

    helper_callpython(pwdir, 'prep_aggregate.py', '--none --MEG');


    % load data
    fprintf('\n*** Loading and controlling raw data. ***\n');
    
    data = helper_load(fullfile(outdir, 'union_MEG_False.txt'));
    data.rtl = log10(data.rt);
    data(data.rtl == -Inf,:).rtl = zeros(nnz(data.rtl == -Inf), 1);
    data.ver = data.list == data.pool;
    data = convertvars(data, {'ppn', 'id', 'spkr', 'var', 'pool', 'list', 'def', 's', 't', 'r', 'ver', 'c'}, 'categorical');
    
    % find repetition indices in data
    ppns = unique(data.ppn);
    j = zeros(size(data, 1), 1);
    w = zeros(size(ppns, 1), 60);

    for i = 1:size(ppns, 1)
        entries = find(data.ppn == ppns(i));

        for k = 1:size(entries, 1)
            t = data(entries(k),:).id;
            w(i,t) = w(i,t) + 1;
            j(entries(k)) = w(i,t);
        end
    end
    
    data.rep = j(:,1);
    
    data_manual = data(find(data.r ~= '-1'),:); % remove no-responses
    [raw_h, raw_p, raw_s, raw_c] = adtest(data_manual.rt);


    % between-participant outliers
    fprintf('\n*** Performing outlier analysis between-ppn. ***\n');

    data_manual_between = data_manual(~isoutlier(data_manual.rt), :);
    [between_h, between_p, between_s, between_c] = adtest(data_manual_between.rt);

    % 
    fprintf('\n*** Performing outlier analysis within-ppn. ***\n');

    data_manual_within = data_manual;
    [within_outliers, ppns] = helper_aggregate(data_manual_within, 'ppn', 'rt', 'isoutlier', true);

    for i = 1:size(ppns, 1)
        idx = find(data_manual_within.ppn == ppns(i, 1));
        data_manual_within(idx(within_outliers{i,1}),:) = [];
    end

    [within_h, within_p, within_s, within_c] = adtest(data_manual_within.rt);


    % visualisation for review
    fprintf('\n*** Visualising data. ***\n');

    figure;
    subplot(3, 2, 1);
    plot(data_manual.i, data_manual.rt, '.'); ylim([0 3500]); xlim([-5 325]); subtitle(sprintf('Manually cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual.rt), raw_s, raw_p));
    subplot(3, 2, 2);
    qqplot(data_manual.rt);
    subplot(3, 2, 3);
    plot(data_manual_between.i, data_manual_between.rt, '.'); ylim([0 3500]); xlim([-5 325]); subtitle(sprintf('Between-participant cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual_between.rt), between_s, between_p));
    subplot(3, 2, 4);
    qqplot(data_manual_between.rt);
    subplot(3, 2, 5);
    plot(data_manual_within.i, data_manual_within.rt, '.'); ylim([0 3500]); xlim([-5 325]); subtitle(sprintf('Within-participant cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual_within.rt), within_s, within_p));
    subplot(3, 2, 6);
    qqplot(data_manual_within.rt);

    % saving and logging
    fprintf('\n*** Saving data. ***\n');

    data_raw = data;

    data = {};
    data.raw = data_raw;
    data.manual = data_manual;
    data.between = data_manual_between;
    data.within = data_manual_within;

    descriptors = {};
    descriptors.raw = [size(data_raw, 1) 0.0];
    descriptors.manual = [size(data_manual, 1) 100 * ((size(data_raw, 1) - size(data_manual, 1)) / size(data_raw, 1)) raw_h raw_p raw_s raw_c]; 
    descriptors.between = [size(data_manual_between, 1) 100 * (size(data_raw, 1) - size(data_manual_between, 1)) / size(data_raw, 1) between_h between_p between_s between_c]; 
    descriptors.within = [size(data_manual_within, 1) 100 * (size(data_raw, 1) - size(data_manual_within, 1)) / size(data_raw, 1) within_h within_p within_s within_c]; 

    save(fullfile(outdir, 'MEG.mat'), 'data', 'descriptors');
end