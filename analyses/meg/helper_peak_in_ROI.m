% @Description: Get coords of a peak voxel in a masked ROI.
% 
% INPUTS:
%   interp      - Interpolated source object
%   mask        - Mask of ROI
%
% OUTPUTS:
%   location    - Location of peak voxel

function [peak, location] = helper_peak_in_ROI(interp, mask)
    [peak, maxindx] = max(abs(interp.stat(find(mask > 0))));
    indx = find(mask);
    maxindx = indx(maxindx);
    [x, y, z] = ind2sub(interp.dim, maxindx); % linear subs
    location = interp.transform * [x y z 1]'; % take into voxel space
    location = location(1:3);
end