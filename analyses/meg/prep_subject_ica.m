% @Description: ICA preprocessing for a particular subject.
%
% INPUTS:
%       subject     -   Subject struct

function prep_subject_ica(subject)
    fprintf('\n*** Running ICA ***\n');
    
    % load data
    load(fullfile(subject.out, 'preproc-data-artreject-400hz.mat'), 'data');
    
    cfg = [];
    cfg.method = 'runica';
    cfg.demean = 'no';
    cfg.channel = {'MEG'};
    
    comp = ft_componentanalysis(cfg, data);
    
    unmixing = comp.unmixing;
    topolabel = comp.topolabel;
    
    save(fullfile(subject.out, 'preproc-ica-weights.mat'), 'unmixing', 'topolabel');
end