% @Description: Helper function for MRI realigment of a subject
% to Polhemus headshape.
%
% INPUTS:
%       subject -   Subject
%
% OUTPUTS:
%       mri     -   Realigned MRI

function mri = prep_geom_realign(subject)
    % read MRI
    fprintf('\n*** Reading MRI ***\n');
    rawmri = ft_read_mri(subject.raw_mri);
    
    % fiducial positions
    fprintf('\n*** Finding fiducial positions ***\n');
    cfg2 = [];
    cfg2.method = 'interactive';
    cfg2.coordsys = 'ctf';
    mri1 = ft_volumerealign(cfg2, rawmri);
    
    % read polhemus
    fprintf('\n*** Reading Polhemus ***\n');
    headshape = ft_read_headshape(subject.raw_pol);
    
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
    save(fullfile(subject.out, 'geom-mri-realigned.mat'), 'mri');
end