% @Description: Creates a confound matrix for linear detrending of MEG
% power. This is essentially complimentary to rsl_SUBS.pcl:ShuffleBlocked()
% that we use before the experiment where variants are essentially our
% blocks in the design.
% 
%
% OUTPUTS:
%   confounds       - Confound matrix

function confounds = helper_get_linear_confound()
    M = 320;
    B = 8;
    L = M / B;
    
    confounds = [(1:M)' mod(1:M, L)'];
    confounds(:,3) = [ones(L, 1)' ones(L, 1)'*2 ones(L, 1)'*3 ones(L, 1)'*4 ones(L, 1)'*5 ones(L, 1)'*6 ones(L, 1)'*7 ones(L, 1)'*8]; % this is terrible code-wise but does the job
end