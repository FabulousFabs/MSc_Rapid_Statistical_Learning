% @Description: Return the mask for a ROI.
% 
% INPUTS:
%   mri         - MRI of target space
%   atlas       - Atlas to use
%   ROI         - Selection of ROIs (cell-array!)
%
% OUTPUTS:
%   mask        - Mask for ROIs

function mask = helper_mask_ROI(mri, atlas, ROI, stat, thr)
    aal = ft_read_atlas(atlas);
    cfg = [];
    cfg.parameter = 'tissue';
    aal2 = ft_sourceinterpolate(cfg, aal, mri); % interpolate atlas on mri
    
    mask_roi = find(ismember(aal.tissuelabel, ROI));
    mask_roi = ismember(aal2.tissue, mask_roi);
    
    if nargin < 4
        mask = mask_roi;
        return;
    end
    
    if nargin < 5
        thr = [0.5 0.8];
    end
    
    dat = abs(stat(mask_roi));

    mask = zeros(size(dat));

    thr = max(dat) .* thr;

    % everything above thr(2) is fully opaque
    mask(dat > thr(2)) = 1;

    % in between thr(1) and thr(2): ramp up nicely
    inds = dat > thr(1) & dat < thr(2);
    x = dat(inds);

    % scale between 0 and 1
    x = (x-min(x)) ./ (max(x)-min(x));

    % make sigmoidal
    beta = 2;
    x = 1 ./ (1 + (x./(1-x)).^-beta);

    mask(inds) = x;
    
    % transform back to full space
    full_mask = zeros(size(stat));
    full_mask(mask_roi) = mask;
    mask = full_mask;
end