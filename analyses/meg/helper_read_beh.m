% @Description: Read behavioural data from MEG session.
%
% INPUTS:
%       cfg     -   Configuration
%
% OUTPUTS:
%       data    -   Data structure of trials where:
%                   1,  2,    3,   4,   5,    6,    7,         8,  
%                   id, spkr, var, dur, pool, list, condition, rt,
%                   9,        10
%                   response, correct

function data = helper_read_beh(cfg)
    assert(isempty(cfg) == false);
    assert(isfield(cfg, 'subject'));
    
    data = readtable(cfg.subject.beh_meg);
    stim_info = table2array(data(:, 1:4)); % id spkr var dur
    cond_info = table2array(data(:, 6:7)); % pool list
    cond_reco = helper_recode_condition(cond_info);
    resp_info = table2array(data(:, 11:13)); % rt, response, correct
    data = [stim_info cond_info cond_reco resp_info];
end