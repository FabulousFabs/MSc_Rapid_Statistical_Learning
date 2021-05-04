% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';

%% Select participant
subjects = helper_datainfo(rootdir);
sid = 5;

%% Compute TFRs (evoked)
subj_tfr_evoked(subjects(sid));

%% Compute TFRs (non-locked)
subj_tfr(subjects(sid));

%% Compute theta source beamformer
subj_source_theta_bf(subjects(sid));

%% Compute beta source beamformer
subj_source_beta_bf(subjects(sid));
