% @Description: Synchronous python call.
%
% INPUTS:
%   dir     - Working directory
%   script  - Python script to call
%   arg     - Vargs to supply 

function helper_callpython(dir, script, arg)
    fprintf('\n*** Calling external python script. ***\n');
    
    system(sprintf('module unload python && module load python/3.4.2 && cd %s && python %s %s', dir, script, arg));
end

