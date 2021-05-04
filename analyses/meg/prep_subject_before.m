% @Description: Preprocesses a particular subject's MEG data
% before ICA.
%
% INPUTS:
%       subject     -   Subject struct

function prep_subject_before(subject)
    % define trials
    fprintf('\n*** Defining trials ***\n');
    
    cfg_dft = [];
    cfg_dft.subject = subject;
    cfg_dft.trialfun = 'helper_make_trial';
    cfg_dft.eventtype = 'frontpanel trigger';
    cfg_dft.eventvalue = [1 3 5 6];
    cfg_dft.trialdef.onset = 2^5;
    cfg_dft.trialdef.offset = 2^7;
    %cfg_dft.trialdef.pre = 1; % old theta only
    %cfg_dft.trialdef.post = 1; % old theta only
    cfg_dft.trialdef.pre = 0.6; % now also including between trials beta window; this raises maximum trial duration to 7071
    cfg_dft.trialdef.post = 1.8; % now also including between trials beta window; this raises maximum trial duration to 7071
    cfg_dft = ft_definetrial(cfg_dft);
    
    % get data
    fprintf('\n*** Loading data. ***\n');
    
    cfg_sel = [];
    cfg_sel.dataset = subject.raw_meg;
    cfg_sel.trl = cfg_dft.trl;
    cfg_sel.channel = {'MEG', 'MEGREF'};
    cfg_sel.continuous = 'yes';
    data = ft_preprocessing(cfg_sel);
    
    % G3BR
    fprintf('\n*** G3BR correction ***\n');
    
    cfg_gbr = [];
    cfg_gbr.gradient = 'G3BR';
    data = ft_denoise_synthetic(cfg_gbr, data);
    
    % demean
    fprintf('\n*** Demeaning ***\n');
    
    cfg_dmn = [];
    cfg_dmn.demean = 'yes';
    data = ft_preprocessing(cfg_dmn, data);
    
    % ft_rejectvisual
    fprintf('\n*** Reject visual ***\n');
    
    cfg_rjv = [];
    cfg_rjv.channel = {'MEG'};
    cfg_rjv.method = 'summary';
    cfg_rjv.layout = 'CTF275.lay';
    data_clean = ft_rejectvisual(cfg_rjv, data);
    
    tri_keep = data_clean.trialinfo(:, 8);
    megchan_keep = data_clean.label;
    
    save(fullfile(subject.out, 'preproc-artifacts-rejectvisual-variance.mat'), 'tri_keep', 'megchan_keep');
    
    % filter for muscle activity
    fprintf('\n*** Reject visual muscle ***\n');
    
    cfg_rjvm = [];
    cfg_rjvm.bpfilter = 'yes';
    cfg_rjvm.bpfreq = [110 140];
    cfg_rjvm.bpfilttype = 'but';
    cfg_rjvm.bpfiltord = 4;
    cfg_rjvm.hilbert = 'yes';
    data_muscle = ft_preprocessing(cfg_rjvm, data_clean);
    
    cfg_rjv = [];
    cfg_rjv.channel = {'MEG'};
    cfg_rjv.method = 'summary';
    cfg_rjv.layout = 'CTF275.lay';
    data_clean = ft_rejectvisual(cfg_rjv, data_muscle);
    
    tri_keep = data_clean.trialinfo(:, 8);
    
    save(fullfile(subject.out, 'preproc-artifacts-rejectvisual-muscle.mat'), 'tri_keep');
    
    % selection of trials/channels
    fprintf('\n*** Removing bad trials/channels ***\n');
    
    cfg_sel2 = [];
    cfg_sel2.channel = {'MEGREF', megchan_keep{:}};
    cfg_sel2.trials = tri_keep;
    data = ft_selectdata(cfg_sel2, data);
    
    % resample
    fprintf('\n*** Resampling ***\n');
    
    cfg_res = [];
    cfg_res.resamplefs = 400;
    cfg_res.demean = 'no';
    cfg_res.detrend = 'no';
    data = ft_resampledata(cfg_res, data);
    
    % save
    fprintf('\n*** Saving ***\n');
    
    save(fullfile(subject.out, 'preproc-data-artreject-400hz.mat'), 'data', '-v7.3');
end