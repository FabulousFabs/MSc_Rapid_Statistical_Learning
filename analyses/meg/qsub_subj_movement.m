% @Description: Compute movement indicators and the corresponding 
% translations/rotations for a subject.

function exit = qsub_subj_movement(subject, rootdir)
    addpath /home/common/matlab/fieldtrip/;
    addpath /project/3018012.23/;
    addpath /project/3018012.23/git/analyses/meg/;
    

    % load cleaned data
    fprintf('\n*** Loading cleaned data ***\n');
    
    data_p = helper_clean_data(subject);
    
    
    % load raw data
    fprintf('\n*** Loading raw data ***\n');
    
    if subject.ppn == 10
        % this was a case where the MEG didn't record the triggers properly
        % so we had to interpolate them after the fact from the
        % behavioural data (for some trials, maybe 10?) so we're going to
        % have to treat it as an exception here, too
        
        load(fullfile(rootdir, 'processed', 'sub-10', 'preproc-fixed-timings-manual.mat'), 'trl');
        cfg = [];
        cfg.trl = trl;
    else
        cfg = [];
        cfg.subject = subject;
        cfg.trialfun = 'helper_make_trial';
        cfg.eventtype = 'frontpanel trigger';
        cfg.eventvalue = [1 3 5 6];
        cfg.trialdef.onset = 2^5;
        cfg.trialdef.offset = 2^7;
        cfg.trialdef.pre = 1.0;
        cfg.trialdef.post = 1.4;
        cfg = ft_definetrial(cfg);
    end
    
    con = [];
    con.dataset = subject.raw_meg;
    con.trl = cfg.trl;
    con.channel = {'HLC0011', 'HLC0012', 'HLC0013', ...
                   'HLC0021', 'HLC0022', 'HLC0023', ...
                   'HLC0031', 'HLC0032', 'HLC0033'};
    con.continuous = 'yes';
    headpos = ft_preprocessing(con);
    
    
    % select trials
    fprintf('\n*** Selecting trials in raw data. ***\n');
    
    cfg = [];
    cfg.trials = data_p.trialinfo(:,8);
    headpos = ft_selectdata(cfg, headpos);
    
    
    % calculate mean coil positions per trial
    fprintf('\n*** Calculating fiducial poisitions and translations. ***\n');
    
    ntrials = length(headpos.sampleinfo);
    
    for t = 1:ntrials
        coil1(:,t) = [mean(headpos.trial{1,t}(1,:)); mean(headpos.trial{1,t}(2,:)); mean(headpos.trial{1,t}(3,:))];
        coil2(:,t) = [mean(headpos.trial{1,t}(4,:)); mean(headpos.trial{1,t}(5,:)); mean(headpos.trial{1,t}(6,:))];
        coil3(:,t) = [mean(headpos.trial{1,t}(7,:)); mean(headpos.trial{1,t}(8,:)); mean(headpos.trial{1,t}(9,:))];
    end
    
    cc = circumcenter(coil1, coil2, coil3);
    cc_dm = [cc - repmat(mean(cc, 2), 1, size(cc, 2))]';
    
    
    % save data
    fprintf('\n*** Saving data. ***\n');
    
    save(fullfile(subject.out, 'regressor-movement.mat'), 'cc', 'cc_dm');
    
    
    % plotting
    fprintf('\n*** Creating plots for visual inspection. ***\n');
    
    f = figure('visible', 'off');
    subplot(4, 1, 1);
    plot(cc_dm(:, 1:3) * 1000);
    title(sprintf('Translations sub-%02d', subject.ppn));
    
    subplot(4, 1, 2);
    plot(cc_dm(:, 4:6));
    title(sprintf('Rotations sub-%02d', subject.ppn));
    
    subplot(4, 1, 3);
    scatter(1:3, max(abs(cc_dm(:, 1:3) * 1000))); hold on
    plot(ones(1, 3) * 5, 'b--'); hold on
    plot(ones(1, 3) * 8, 'r--'); hold on
    xlim([0 4]);
    ylim([0 10]);
    title(sprintf('Maximum position change sub-%02d', subject.ppn));
    
    subplot(4, 1, 4);
    plot(sum(abs(cc_dm(:, 1:3) * 1000), 2)); hold on
    plot(ones(1, ntrials) * 5, 'b--'); hold on
    plot(ones(1, ntrials) * 8, 'r--'); hold on
    ylim([0 10]);
    title(sprintf('Movement indicator sub-%02d', subject.ppn));
    
    saveas(f, fullfile(rootdir, 'processed', 'combined', 'movement', sprintf('sub-%02d.png', subject.ppn)), 'png');
    
    exit = true;
end