% @Description: Compute offsets to redefine trials for beta TOI.
% 
% INPUTS:
%   trialinfo   - data.trialinfo struct
%
% OUTPUTS:
%   offset      - Offset vector for all trials

function offset = helper_clean_data(trialinfo, fs)
    offset = floor(((1/fs) * ((trialinfo(:,5) + 300 + trialinfo(:,9)) / 1000)) * 1000)
end