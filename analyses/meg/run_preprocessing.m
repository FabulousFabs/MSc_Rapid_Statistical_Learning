% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /users/fabianschneider/Documents/matlab/fieldtrip;
addpath /users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg;
ft_defaults;

rootdir = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg/';
sourcemodel_loc = '/users/fabianschneider/Documents/MATLAB/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';
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

%% preprocess MRI/pol alignment
prep_geom_realign(subjects(sid));

%% preprocess MRI segmentation and lead fields
prep_geom_segmentmri_and_leadfield(subjects(sid), sourcemodel_loc);