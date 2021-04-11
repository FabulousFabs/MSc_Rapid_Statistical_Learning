% @Description: Make trials from trigger data.
%
% INPUTS:
%       cfg     -   Configuration
%
% OUTPUTS:
%       trl     -   Trial segmentation
%       event   -   Event data

function [trl, event] = helper_make_trial(cfg)
    % safety
    assert(isempty(cfg) == false);
    assert(isfield(cfg, 'dataset'));
    assert(isfield(cfg, 'trialdef'));
    assert(isfield(cfg.trialdef, 'pre'));
    assert(isfield(cfg.trialdef, 'post'));
    assert(isfield(cfg, 'eventtype'));
    assert(isfield(cfg, 'eventvalue'));
    assert(isfield(cfg.trialdef, 'onset'));
    assert(isfield(cfg.trialdef, 'offset'));
    
    % read header & events
    hdr = ft_read_header(cfg.dataset);
    event = ft_read_event(cfg.dataset);
    
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
    
    offset = pretrig * ones(length(trl_onset_value), 1);
    
    trl = [real_onset_sample real_offset_sample offset trl_onset_value];
end