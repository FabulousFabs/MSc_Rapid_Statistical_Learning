% @Description: MRI segmentation and leadfield for subject.
%
% INPUTS:
%       subject -   Subject
%       ssm     -   Location of standard source model

function prep_geom_segmentmri_and_leadfield(subject, ssm)
    % load realigned mri
    fprintf('\n*** Loading MRI ***');
    load(fullfile(subject.out, 'geom-mri-realigned.mat'), 'mri');
    
    % segment mri and store mask
    fprintf('\n*** Segmenting and storing ***\n');
    cfg = [];
    cfg.output = 'brain';
    segmentedmri = ft_volumesegment(cfg, mri);
    
    save(fullfile(subject.out, 'geom-mri-segmented.mat'), 'segmentedmri');
    
    % prepare head model
    fprintf('\n*** Preparing head model ***\n');
    
    cfg = [];
    cfg.method = 'singleshell';
    headmodel = ft_prepare_headmodel(cfg, segmentedmri);
    
    load(fullfile(ssm), 'sourcemodel');
    template_grid = sourcemodel;
    clear sourcemodel;
    
    % prepare source model
    fprintf('\n*** Preparing source model ***\n');
    
    cfg = [];
    cfg.grid.warpmni = 'yes';
    cfg.grid.template = template_grid;
    cfg.grid.nonlinear = 'yes';
    cfg.grid.unit = 'mm';
    cfg.mri = mri;
    grid = ft_prepare_sourcemodel(cfg);
    
    % load cleaned meg data
    fprintf('\n*** Loading and cleaning data ***\n');
    
    data = helper_clean_data(subject);
    
    % preparing lead field
    fprintf('\n*** Preparing lead field ***\n');
    
    cfg = [];
    cfg.headmodel = headmodel;
    cfg.grid = grid;
    cfg.channel = {'MEG'};
    cfg.reducerank = 2;
    leadfield = ft_prepare_leadfield(cfg, data);
    
    % save
    fprintf('\n*** Saving head model and lead field ***\n');
    save(fullfile(subject.out, 'geom-leadfield-mni-8mm-megchans.mat'), 'headmodel', 'leadfield', '-v7.3');
end