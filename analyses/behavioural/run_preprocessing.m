% @description: Run preprocessing of all behavioural data.

% setup
clearvars; close all;

rootdir = '/project/3018012.23/';
pwdir = fullfile(rootdir, 'git', 'analyses', 'behavioural');
outdir = fullfile(rootdir, 'processed', 'combined');

% run preprocessing steps
prep_4AFC(pwdir, outdir);
prep_MEG(pwdir, outdir);