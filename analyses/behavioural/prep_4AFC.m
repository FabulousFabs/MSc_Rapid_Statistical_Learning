% @Description: Prepare 4AFC data for modelling.
%
% INPUTS:
%   pwdir   - Present working directory (for python)
%   outdir  - Directory for exports

function prep_4AFC(pwdir, outdir)
    fprintf('\n*** Starting preprocessing of 4AFC data. ***\n');

    % run external aggregation
    fprintf('\n*** Collecting data. ***\n');

    helper_callpython(pwdir, 'prep_aggregate.py', '--none --4AFC');


    % load data
    fprintf('\n*** Loading data, fixing and recoding. ***\n');

    data = helper_load(fullfile(outdir, 'union_4AFC_False.txt'));
    data.loc = helper_recodelocation(data);
    data.rtl = log10(data.rt);
    dummy = data.spkr;
    data.spkr = data.id;
    data.id = dummy;
    data = convertvars(data, {'ppn', 'id', 'spkr', 'var', 'pool', 'list', 'def', 's', 'o1', 'o2', 'o3', 'o4', 'loc'}, 'categorical');
    
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
    

    % data cleaning by ppn
    fprintf('\n*** Cleaning data by participant. ***\n');

    [hr_by_ppn, ppns] = helper_aggregate(data, 'ppn', 'cor', 'mean');
    helper_plothr(ppns, hr_by_ppn, 'ppn');
    remove_ppns = ppns(helper_collectcomponents());


    % data cleaning by word
    fprintf('\n*** Cleaning data by word. ***\n');

    [hr_by_word, words] = helper_aggregate(data, 'id', 'cor', 'mean');
    helper_plothr(words, hr_by_word, 'word');
    remove_words = words(helper_collectcomponents());


    % data cleaning by speaker
    fprintf('\n*** Cleaning data by speaker. ***\n');

    [hr_by_speaker, speakers] = helper_aggregate(data, 'spkr', 'cor', 'mean');
    helper_plothr(speakers, hr_by_speaker, 'speaker');
    remove_speakers = speakers(helper_collectcomponents());


    % data cleaning by definition
    fprintf('\n*** Cleaning data by definition. ***\n');

    [hr_by_definition, definitions] = helper_aggregate(data, 'def', 'cor', 'mean');
    helper_plothr(definitions, hr_by_definition, 'definition');
    remove_definitions = definitions(helper_collectcomponents());


    % save components
    fprintf('\n*** Saving and cleaning. ***\n');

    save(fullfile(outdir, '4AFC_badcomps.mat'), 'remove_ppns', 'remove_words', 'remove_speakers', 'remove_definitions');

    remove = ismember(data.ppn, remove_ppns) | ...
             ismember(data.id, remove_words) | ...
             ismember(data.spkr, remove_speakers) | ...
             ismember(data.def, remove_definitions);
    data_manual = data(~remove,:);
    [raw_h, raw_p, raw_s, raw_c] = adtest(data_manual.rt);


    % between-participant outliers
    fprintf('\n*** Performing outlier analysis between-ppn. ***\n');

    data_manual_between = data_manual(~isoutlier(data_manual.rt), :);
    [between_h, between_p, between_s, between_c] = adtest(data_manual_between.rt);
    

    % within-participant outliers
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
    plot(data_manual.i, data_manual.rt, '.'); ylim([0 6500]); xlim([-5 185]); subtitle(sprintf('Manually cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual.rt), raw_s, raw_p));
    subplot(3, 2, 2);
    qqplot(data_manual.rt);
    subplot(3, 2, 3);
    plot(data_manual_between.i, data_manual_between.rt, '.'); ylim([0 6500]); xlim([-5 185]); subtitle(sprintf('Between-participant cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual_between.rt), between_s, between_p));
    subplot(3, 2, 4);
    qqplot(data_manual_between.rt);
    subplot(3, 2, 5);
    plot(data_manual_within.i, data_manual_within.rt, '.'); ylim([0 6500]); xlim([-5 185]); subtitle(sprintf('Within-participant cleaned data, AD(%.0d) = %d, p = %.3d.', numel(data_manual_within.rt), within_s, within_p));
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

    save(fullfile(outdir, '4AFC.mat'), 'data', 'descriptors');
end