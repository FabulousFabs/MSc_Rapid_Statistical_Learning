% @Description: Helper function for MRI realigment of a subject
% to Polhemus headshape.
%
% INPUTS:
%       cfg     -   Configuration
%
% OUTPUTS:
%       mri     -   Realigned MRI

function mri = helper_geom_realign(cfg)
    assert(isempty(cfg) == false);
    assert(isfield(cfg, 'subject'));
    
    % read MRI
    fprintf('\n*** Reading MRI ***\n');
    rawmri = ft_read_mri(cfg.subject.raw_mri);
    
    % fiducial positions
    fprintf('\n*** Finding fiducial positions ***\n');
    cfg2 = [];
    cfg2.method = 'interactive';
    cfg2.coordsys = 'ctf';
    mri1 = ft_volumerealign(cfg2, rawmri);
    
    % read polhemus
    fprintf('\n*** Reading Polhemus ***\n');
    headshape = ft_read_headshape(cfg.subject.raw_pol);
    
    % icp
    fprintf('\n*** Running ICP ***\n');
    cfg3 = [];
    cfg3.method = 'headshape';
    cfg3.coordsys = 'ctf';
    cfg3.headshape.headshape = headshape;
    cfg3.headshape.interactive = 'no';
    cfg3.headshape.icp = 'yes';
    mri2 = ft_volumerealign(cfg3, mri1);
    
    fprintf('RMS error before icp: %.3f\n', sqrt(mean(mri2.cfg.icpinfo.distancein.^2)));
    fprintf('RMS error after icp:  %.3f\n', sqrt(mean(mri2.cfg.icpinfo.distanceout.^2)));
    
    % final alignment + check
    fprintf('\n*** Final alignment ***\n');
    cfg3.headshape.interactive = 'yes';
    cfg3.headshape.icp = 'no';
    mri = ft_volumerealign(cfg3, mri2);
    
    % save MRI
    fprintf('\n*** Saving MRI ***\n');
    save(fullfile(cfg.subject.out, 'geom-mri-realigned.mat'), 'mri');
end