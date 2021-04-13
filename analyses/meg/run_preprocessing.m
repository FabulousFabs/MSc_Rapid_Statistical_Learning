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

%% geom realign
cfg = [];
cfg.subject = subjects(sid);
helper_geom_realign(cfg);
