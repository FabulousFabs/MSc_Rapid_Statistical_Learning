% @Description: Separate trials from data.trialinfo into
% the conditions of conds (also downsamples to equalise
% length between conditions).

function partitions = helper_partition_trials(data, conds)
    assert(isempty(data) == false);
    assert(isfield(data, 'trialinfo'));
    assert(isempty(data.trialinfo) == false);
    assert(isempty(conds) == false);
    
    % setup
    partitions = {};
    N = Inf;
    
    for i = 1:length(conds)
        partitions{i} = [];
        partitions{i}.code = conds(i);
        partitions{i}.indices = find(data.trialinfo(:, 1) == conds(i));
        if length(partitions{i}.indices) < N 
            N = length(partitions{i}.indices);
        end
    end
    
    % we could resample at this stage
    % such that conditions are all of same N
    % although i'm not convinced yet we will
    % really _have_ to do this and don't 
    % wanna waste data
    % here goes:
    
    for i = 1:length(conds)
        if length(partitions{i}.indices) > N
            partitions{i}.indices = randsample(partitions{i}.indices, N);
        end
    end
end

