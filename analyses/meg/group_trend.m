% @Description: Compute power-trends for all subjects.

function group_trend(subjects, rootdir)
    % load all data
    fprintf('\n*** Loading all subject data. ***\n');

    subj = {};

    for k = 1:size(subjects, 2)
        fprintf('\n*** Loading k=%d for sub-%02d. ***\n', k, subjects(k).ppn);

        subject = subjects(k);
        data = helper_clean_data(subject);

        cfg = [];
        cfg.avgoverchan = 'yes';
        subj{end+1} = ft_selectdata(cfg, data);

        clear data;
    end

    
    % figure for all data
    f1 = figure('visible', 'off');

    for k = 1:size(subjects, 2)
        subplot(4, 8, k);
        subject = subjects(k);
        title(sprintf('sub-%02d', subject.ppn));

        current = 1;
        data_avg = subj{k};

        for i = 1:size(data_avg.trial, 2)
            new = current + size(data_avg.trial{i}, 2) - 1;
            plot(current:new, data_avg.trial{i}); hold on
            current = new;
        end
    end

    saveas(f1, fullfile(rootdir, 'processed', 'combined', 'trend', 'full_trials.png'), 'png');

    
    % figure by trial
    f2 = figure('visible', 'off');

    for k = 1:size(subjects, 2)
        subplot(4, 8, k);
        subject = subjects(k);
        title(sprintf('sub-%02d', subject.ppn));

        means = [];
        data_avg = subj{k};

        for i = 1:size(data_avg.trial, 2)
            trl = [data_avg.trial{i}];
            means(end+1) = mean(trl);
        end

        plot(means);
    end

    saveas(f2, fullfile(rootdir, 'processed', 'combined', 'trend', 'by_trial.png'), 'png');

    
    % figure by block
    f3 = figure('visible', 'off');

    for k = 1:size(subjects, 2)
        subplot(4, 8, k);
        subject = subjects(k);
        title(sprintf('sub-%02d', subject.ppn));

        means = [];
        data_avg = subj{k};

        for i = 1:8
            trls = (data_avg.trialinfo(:, 8) > ((i-1) * 40)) & (data_avg.trialinfo(:, 8) < (i * 40));
            indx = find(trls);
            block = [data_avg.trial{indx}];
            means(end+1) = mean(block);
        end

        plot(means);
    end

    saveas(f3, fullfile(rootdir, 'processed', 'combined', 'trend', 'by_block.png'), 'png');

    
    % figure within block
    f4 = figure('visible', 'off');

    for k = 1:size(subjects, 2)
        subplot(4, 8, k);
        subject = subjects(k);
        title(sprintf('sub-%02d', subject.ppn));

        means = [];
        data_avg = subj{k};

        for i = 1:40
            trls = i + (0:7) * 40;
            indx = find(ismember(data_avg.trialinfo(:, 8), trls));
            rpts = [data_avg.trial{indx}];
            means(end+1) = mean(rpts);
        end

        plot(means);
    end

    saveas(f4, fullfile(rootdir, 'processed', 'combined', 'trend', 'by_item_in_block.png'), 'png');
end