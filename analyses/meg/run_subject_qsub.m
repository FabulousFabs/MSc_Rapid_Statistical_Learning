% @Description: Runs processing steps for all subjects in qsubs.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;
addpath /home/common/matlab/fieldtrip/qsub;

ft_defaults;

rootdir = '/project/3018012.23/';

% Get participant info
subjects = helper_datainfo(rootdir);

% Load preprocessed states
progressdir = '/project/3018012.23/processed/combined/';
progressf = 'preprocessing_completed.mat';
load(fullfile(progressdir, progressf), 'prep_comp_subs');

% Initialise job id tracking
subject_jobs = {};
jobdir = '/project/3018012.23/.jobs/';
jobf = 'jobs.mat';

cd /project/3018012.23/.jobs/;

% Launch qsubs for each participant
for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we run only if preprocessing complete (technical detail
    % useful only while full data isnt yet available, i.e. when i'm writing
    % this)
    if ~any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (not yet preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    % technically, these jobs should all finish <30min, but it looks like
    % we are hitting some resource constraints on the cluster that slows
    % down some jobs extremely, ergo we're going to give them a lot of
    % extra time to finish running
    subject_jobs{end+1} = qsubfeval(@qsub_run_subject, rootdir, subject, 'memreq', 16*(1024^3), 'timreq', 120*60*1);
end

cd /project/3018012.23/git/analyses/meg/;

save(fullfile(jobdir, jobf), 'subject_jobs');

%% read qsubs
load(fullfile(jobdir, jobf), 'subject_jobs');
cd /project/3018012.23/.jobs/;

outputs = {};
for k = 1:size(subject_jobs, 2)
    outputs{end+1} = qsubget(subject_jobs{k});
end

cd /project/3018012.23/git/analyses/meg/;
fprintf('*** Check the outputs manually, please. ***\n');