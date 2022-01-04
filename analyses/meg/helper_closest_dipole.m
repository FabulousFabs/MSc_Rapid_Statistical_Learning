% @Description: Get closest dipole to MNI point-of-interest.

function [v, indx] = helper_closest_dipole(poi, pos)
    poi = poi ./ 10;
    [v, indx] = min(sum(abs(pos - repmat(poi, size(pos, 1), 1)), 2));
end