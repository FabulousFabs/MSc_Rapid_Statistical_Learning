% @Description: Preprocesses a particular subject's MEG data
% as per the configuration passed.
%
% INPUTS:
%       cfg     -   Configuration

function [data, data_raw] = run_single_subject(cfg)
    % safety
    assert(isempty(cfg) == false);
    assert(isfield(cfg, 'rootdir'));
    assert(isfield(cfg, 'dataset'));
    
    % define trials
    fprintf('\n*** Defining trials. ***\n');
    
    cfg_dft = [];
    cfg_dft.dataset = fullfile(cfg.rootdir, 'raw', cfg.dataset);
    cfg_dft.trialfun = 'helper_make_trial';
    cfg_dft.eventtype = 'frontpanel trigger';
    cfg_dft.eventvalue = [1 3 5 6];
    cfg_dft.trialdef.onset = 2^5;
    cfg_dft.trialdef.offset = 2^7;
    cfg_dft.trialdef.pre = 1;
    cfg_dft.trialdef.post = 1;
    cfg_dft = ft_definetrial(cfg_dft);
    
    % get data
    fprintf('\n*** Loading data. ***\n');
    
    cfg_sel = [];
    cfg_sel.dataset = fullfile(cfg.rootdir, 'raw', cfg.dataset);
    cfg_sel.trl = cfg_dft.trl;
    cfg_sel.channel = {'MEG', 'MEGREF'};
    cfg_sel.continuous = 'yes';
    data = ft_preprocessing(cfg_sel);
    data_raw = data;
    
    % 3rd order gradient correction
    fprintf('\n*** G3BR correction ***\n');
    
    cfg_gbr = [];
    cfg_gbr.gradient = 'G3BR';
    data = ft_denoise_synthetic(cfg_gbr, data);
    
    % demean
    fprintf('\n*** Demeaning ***\n');
    
    cfg_dmn = [];
    cfg_dmn.demean = 'yes';
    data = ft_preprocessing(cfg_dmn, data);
    
    %% ft_reject visual
    %cfg_rjv = [];
    %cfg_rjv.method = 'trial';
    %cfg_rjv.ylim = [-1e-12 1e-12];
    %cfg_rjv.megscale = 1;
    %cfg_rjv.eogscale = 5e-8;
    %dummy = ft_rejectvisual(cfg_rjv, data);
    
    % ft_rejectvisual
    %fprintf('\n*** Reject visual ***\n');
    
    %cfg_rjv = [];
    %cfg_rjv.channel = {'MEG'};
    %cfg_rjv.method = 'summary';
    %cfg_rjv.layout = 'CTF275.lay';
    %data_clean = ft_rejectvisual(cfg_rjv, data);
    %data_keep = data_clean.trialinfo(:, 2);
    %megchan_keep = data_clean.label;
    
end