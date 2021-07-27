% @Description: Runs processing steps for all subjects.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';

% Load participant info
subjects = helper_datainfo(rootdir);

% Load preprocessed states
progressdir = '/project/3018012.23/processed/combined/';
progressf = 'preprocessing_completed.mat';
load(fullfile(progressdir, progressf), 'prep_comp_subs');

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we run only if preprocessing complete (technical detail
    % useful only while full data isnt yet available, i.e. when i'm writing
    % this)
    if ~any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (not yet preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    fprintf('\n*** Processing data for k=%d, sub-%02d. *** \n', k, subject.ppn);
    
    % for the full data this is the point in time where i would want to run
    % separate qsubs per k such that we can save some time - one run of the
    % functions below should be 30mins ish so that's acceptable
    
    subj_tfr(rootdir, subject);
    subj_tfr_evoked(rootdir, subject);
    subj_tfr_btwn(rootdir, subject);
    subj_tfr_evoked_btwn(rootdir, subject);
    
    if subject.ppn == 32
        fprintf('\n*** Partial skip for k=%d, sub-%02d (no MRI acquired due to early exclusion). ***\n', k, subject.ppn);
        continue
    end
    
    subj_source_theta_bf(subject);
    subj_source_beta_bf(subject);
    subj_source_beta_bf_btwn(subject);
end

%% re-run
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';

% Load participant info
subjects = helper_datainfo(rootdir);

% Load preprocessed states
progressdir = '/project/3018012.23/processed/combined/';
progressf = 'preprocessing_completed.mat';
load(fullfile(progressdir, progressf), 'prep_comp_subs');

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we run only if preprocessing complete (technical detail
    % useful only while full data isnt yet available, i.e. when i'm writing
    % this)
    if ~any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (not yet preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    fprintf('\n*** Processing data for k=%d, sub-%02d. *** \n', k, subject.ppn);
    
    % for the full data this is the point in time where i would want to run
    % separate qsubs per k such that we can save some time - one run of the
    % functions below should be 30mins ish so that's acceptable
    
    subj_source_theta_bf(subject);
end

