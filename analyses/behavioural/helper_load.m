% @Description: Load aggregated data of some behavioural task.
%
% INPUTS:
%   f       - File to load
%
% OUTPUTS:
%   data    - Data structure

function data = helper_load(f)
    data = readtable(f);
end

