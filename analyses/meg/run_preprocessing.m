% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /users/fabianschneider/Documents/matlab/fieldtrip;
addpath /users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg;
ft_defaults;

rootdir = '/users/fabianschneider/desktop/university/master/dissertation/project/analyses/meg/';

%% Setup run of subject007
cfg = [];
cfg.rootdir = rootdir;
cfg.dataset = 'sub007ses01SPEZL_3018012.23_20210410_01.ds';
[data, data_raw] = run_single_subject(cfg);
fprintf('*** Done ***');

%%
cfg2 = [];
cfg2.channel = 'MEG';
artf = ft_databrowser(cfg2, data);