% @Description: Short-hand utility function for R-style aggregate().
%
% INPUTS:
%   data        -   Data structure
%   grouping    -   Name of grouping variable in data structure
%   var         -   Name of aggregation variable in data structure
%   fun         -   Function to perform over aggregated data
%
% OUTPUTS:
%   aggregate   -   Function output over aggregation
%   groups      -   Unique groupings

function [aggregate, groups] = helper_aggregate(data, grouping, var, fun, cell)
    if exist('cell', 'var')
        aggregate = eval(sprintf('arrayfun(@(x) %s(data(strcmp(string(data.%s), string(x)),:).%s), unique(data.%s), "UniformOutput", false);', fun, grouping, var, grouping));
    else
        aggregate = eval(sprintf('arrayfun(@(x) %s(data(strcmp(string(data.%s), string(x)),:).%s), unique(data.%s));', fun, grouping, var, grouping));
    end
    
    groups = eval(sprintf('unique(data.%s);', grouping));
end