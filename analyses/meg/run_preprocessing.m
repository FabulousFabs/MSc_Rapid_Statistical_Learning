% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /users/fabianschneider/Documents/matlab/fieldtrip;
addpath /users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg;
ft_defaults;

rootdir = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg/';
subjects = helper_datainfo(rootdir);
sid = 1;

%% preprocess before
prep_subject_before(subjects(sid));

%% preprocess ICA
prep_subject_ica(subjects(sid));

%% preprocess after: visual
prep_subject_after(subjects(sid));

%% preprocess after: jot down & save!
badcomps = [];
badcomps_reasons = {};

save(fullfile(subjects(sid).out, 'preproc-ica-badcomps.mat'), 'badcomps', 'badcomps_reasons');

%% 