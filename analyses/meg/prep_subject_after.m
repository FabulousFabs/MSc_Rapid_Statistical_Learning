% @Description: Preprocess a particular subject's MEG data
% after ICA.
%
% INPUTS:
%       subject     -   Subject struct

function prep_subject_after(subject)
    fprintf('\n*** Loading data ***\n');
    
    load(fullfile(subject.out, 'preproc-data-artreject-400hz.mat'), 'data');
    load(fullfile(subject.out, 'preproc-ica-weights.mat'), 'unmixing', 'topolabel');
    
    cfg = [];
    cfg.method = 'predefined mixing matrix';
    cfg.demean = 'no';
    cfg.channel = {'MEG'};
    cfg.topolabel = topolabel;
    cfg.unmixing = unmixing;
    comp = ft_componentanalysis(cfg, data);
    
    fprintf('\n*** Visual inspection; DO NOT FORGET TO JOT DOWN COMPONENTS & SAVE ***\n');
    cfg = [];
    cfg.viewmode = 'component';
    cfg.layout = 'CTF275_helmet.mat';
    ft_databrowser(cfg, comp);
end