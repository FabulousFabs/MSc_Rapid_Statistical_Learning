% @Description: Loads cleaned MEG data.
% 
% INPUTS:
%   subject     - Subject
%
% OUTPUTS:
%   data        - Cleaned data

function data = helper_clean_data(subject)
    % load initial cleaned data
    load(fullfile(subject.out, 'preproc-data-artreject-400hz.mat'), 'data');
    
    % load ica decomp weights and bad components
    load(fullfile(subject.out, 'preproc-ica-weights.mat'), 'unmixing', 'topolabel');
    load(fullfile(subject.out, 'preproc-ica-badcomps.mat'), 'badcomps');
    
    % apply demixing
    cfg = [];
    cfg.demean = 'no';
    cfg.method = 'predefined unmixing matrix';
    cfg.unmixing = unmixing;
    cfg.topolabel = topolabel;
    data = ft_componentanalysis(cfg, data);
    
    % reject bad components
    cfg = [];
    cfg.demean = 'no';
    cfg.component = badcomps;
    data = ft_rejectcomponent(cfg, data);
end