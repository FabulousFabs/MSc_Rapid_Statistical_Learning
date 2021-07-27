% @Description: Recode the location of a displayed target in 4AFC.
%
% INPUTS:
%   data    - Data structure
%
% OUTPUTS:
%   loc     - Recoded labels

function loc = helper_recodelocation(data)
    loc = repelem("bottom_right", size(data, 1), 1);
    loc(data.def == data.o1) = repelem("top_left", nnz(data.def == data.o1), 1);
    loc(data.def == data.o2) = repelem("bottom_left", nnz(data.def == data.o2), 1);
    loc(data.def == data.o3) = repelem("top_right", nnz(data.def == data.o3), 1);
end

