% @Description: Make trials from trigger data.
%
% INPUTS:
%       cfg     -   Configuration
%
% OUTPUTS:
%       trl     -   Trial segmentation where:
%                   1: sample_onset, 2: sample_offset, 3: offset, 4: condition, 5: id,
%                   6: spkr, 7: var, 8: dur, 9: pool, 10: list, 11: no.
%       event   -   Event data

function [trl, event] = helper_make_trial(cfg)
    assert(isempty(cfg) == false);
    assert(isfield(cfg, 'subject'));
    assert(isfield(cfg, 'trialdef'));
    assert(isfield(cfg.trialdef, 'pre'));
    assert(isfield(cfg.trialdef, 'post'));
    assert(isfield(cfg, 'eventtype'));
    assert(isfield(cfg, 'eventvalue'));
    assert(isfield(cfg.trialdef, 'onset'));
    assert(isfield(cfg.trialdef, 'offset'));
    
    % behavioural events
    cfg_beh = [];
    cfg_beh.subject = cfg.subject;
    beh = helper_read_beh(cfg_beh);
    
    % read header & events
    hdr = ft_read_header(cfg.subject.raw_meg);
    event = ft_read_event(cfg.subject.raw_meg);
    
    pretrig = -round(cfg.trialdef.pre * hdr.Fs);
    posttrig = round(cfg.trialdef.post * hdr.Fs);
    
    % find triggers
    me_value = [event(find(strcmp(cfg.eventtype, {event.type}))).value]';
    me_sample = [event(find(strcmp(cfg.eventtype, {event.type}))).sample]';
    
    % find trial tags in data
    tag_m = ismember(me_value, cfg.eventvalue);
    tag_idx = find(tag_m);
    trl_onset_value = me_value(tag_idx);
    
    % find real onset in data
    onset_m = me_value(:) == cfg.trialdef.onset;
    onset_idx = find(onset_m);
    real_onset_sample = me_sample(onset_idx) + pretrig;
    
    % find real offset in data
    offset_m = me_value(:) == cfg.trialdef.offset;
    offset_idx = find(offset_m);
    real_offset_sample = me_sample(offset_idx) + posttrig;
    
    % set offsets
    offset = pretrig * ones(length(trl_onset_value), 1);
    
    % check meg vs beh triggers
    assert(all(trl_onset_value(:) == beh(:, 7)));
    
    % make trl mat
    trl = [real_onset_sample real_offset_sample offset trl_onset_value beh(:, 1:6) (1:length(beh))' ];
end