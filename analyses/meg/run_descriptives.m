% @Description: Runs all group-level analyses.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;

ft_defaults;

rootdir = '/project/3018012.23/';

subjects = helper_datainfo(rootdir);

trls = zeros(1, size(subjects, 2));
chan = zeros(1, size(subjects, 2));

for k = 1:size(subjects, 2)
    load(fullfile(subjects(k).out, 'preproc-artifacts-rejectvisual-variance.mat'), 'megchan_keep');
    chan(k) = size(megchan_keep, 1);
    clear megchan_keep;
    
    load(fullfile(subjects(k).out, 'preproc-artifacts-rejectvisual-muscle.mat'), 'tri_keep');
    trls(k) = size(tri_keep, 1);
    clear tri_keep;
end

fprintf('\n Kept %d +- %d trials. \n', round(mean(trls)), round(std(trls)));
fprintf('\n Kept %d +- %d channels. \n', round(mean(chan)), round(std(chan)));