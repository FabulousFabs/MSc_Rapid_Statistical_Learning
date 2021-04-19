% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

%% Select participant
subjects = helper_datainfo(rootdir);
sid = 3;

%% preprocess before
prep_subject_before(subjects(sid));

%% preprocess ICA
prep_subject_ica(subjects(sid)); % we could run ICAs as a qsub at 32GB

%% preprocess after: visual
prep_subject_after(subjects(sid));

%% preprocess after: jot down & save!
badcomps = [4, 5, 9];
badcomps_reasons = {"eog", "eog", "ecg"};

save(fullfile(subjects(sid).out, 'preproc-ica-badcomps.mat'), 'badcomps', 'badcomps_reasons');

%% preprocess MRI/pol alignment
prep_geom_realign(subjects(sid));

%% preprocess MRI segmentation and lead fields
prep_geom_segmentmri_and_leadfield(subjects(sid), sourcemodel_loc);
