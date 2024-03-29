% @Description: Batch graphical preprocessing of subject data.

clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

progressdir = '/project/3018012.23/processed/combined/';
progressf = 'preprocessing_completed.mat';
load(fullfile(progressdir, progressf), 'prep_comp_subs');

subjects = helper_datainfo(rootdir);

%%

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we preprocess only once per subject
    if any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (already preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    % make sure we preprocess only if data is complete (i.e., MRI acquired)
    if ~isfield(subject, 'raw_mri') || isempty(subject.raw_mri)
        fprintf('\n*** Skipping for k=%d, sub-%02d (no MRI yet). ***\n', k, subject.ppn);
        continue
    end
    
    
    fprintf('\n*** Starting preprocessing data for k=%d, sub-%02d. *** \n', k, subject.ppn);
    
    % ideally, I would want to run the ICAs as individual qsubs but given
    % that we're not scanning fast enough due to all the issues that have
    % been going on, that won't be an efficient use of our time. instead,
    % we're running it sequentially here.
    % create another graphical matlab job to compute stuff in the mean
    % time.
    
    prep_subject_before(subject);
    prep_subject_ica(subject);
    
    fprintf('*** Please jot down bad comps and reasons now. ***\n');
    prep_subject_after(subject);
    
    badcomps = [];
    badcomps_reasons = {};
    
    while 1
        comp = input('Which component should be flagged bad? (<=0 to exit)');
        
        if comp < 1
            break
        end
        
        reason = input('What is the reason for removing the component? (e.g., EOG eye artifact; ECG cardiac artifact)', 's');
        
        badcomps(end+1) = comp;
        badcomps_reasons{end+1} = reason;
    end
    
    save(fullfile(subject.out, 'preproc-ica-badcomps.mat'), 'badcomps', 'badcomps_reasons');
    
    prep_geom_realign(subject);
    prep_geom_segmentmri_and_leadfield(subject, sourcemodel_loc);
    
    prep_comp_subs(end+1) = subject.ppn;
    save(fullfile(progressdir, progressf), 'prep_comp_subs');
    
    if input('Continue with next subject? (Y/N)', 's') ~= 'Y'
        break
    end
end

%% run trend visualisation
group_trend(subjects, rootdir);


%% run qsubs for movement control (final quality checks)
% Initialise job id tracking
mvm_jobs = {};
jobdir = '/project/3018012.23/.jobs/';
jobf = 'jobs.mat';

cd /project/3018012.23/.jobs/;

% Launch qsubs for each participant
for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % technically, these jobs should all finish <5min, but it looks like
    % we are hitting some resource constraints on the cluster that slows
    % down some jobs extremely, ergo we're going to give them a lot of
    % extra time to finish running
    mvm_jobs{end+1} = qsubfeval(@qsub_subj_movement, subject, rootdir, 'memreq', 16*(1024^3), 'timreq', 15*60*1);
end

cd /project/3018012.23/git/analyses/meg/;

save(fullfile(jobdir, jobf), 'mvm_jobs');


%% read qsubs for movement control (final quality checks)
load(fullfile(jobdir, jobf), 'mvm_jobs');
cd /project/3018012.23/.jobs/;

outputs = {};
for k = 1:size(mvm_jobs, 2)
    outputs{end+1} = qsubget(mvm_jobs{k});
end

cd /project/3018012.23/git/analyses/meg/;
fprintf('*** Check the outputs manually, please. ***\n');
fprintf('*** Also make sure to change the inclusion specifications in helper_datainfo _NOW_. ***\n');

