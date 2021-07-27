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
fprintf('\n*** Running before-ICA. ***\n');

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we preprocess only once per subject
    if any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (already preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    prep_subject_before(subject);
    
    if input('Continue with next subject? (Y/N)', 's') ~= 'Y'
        break
    end
end


%% 
fprintf('\n*** Running ICAs. ***\n');

ica_jobs = {};
jobdir = '/project/3018012.23/.jobs/';
jobf = 'jobs.mat';

cd /project/3018012.23/.jobs/;

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we preprocess only once per subject
    if any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (already preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
    ica_jobs{end+1} = qsubfeval(@prep_subject_ica, subject, 'memreq', 16*(1024^3), 'timreq', 360*60*1);
end

cd /project/3018012.23/git/analyses/meg/;

save(fullfile(jobdir, jobf), 'subject_jobs');

%%
fprintf('\n*** Fetching ICAs. ***\n');

load(fullfile(jobdir, jobf), 'ica_jobs');
cd /project/3018012.23/.jobs/;

outputs = {};
for k = 1:size(subject_jobs, 2)
    outputs{end+1} = qsubget(ica_jobs{k});
end

cd /project/3018012.23/git/analyses/meg/;
fprintf('*** Check the outputs manually, please. ***\n');

%%
fprintf('\n*** Visual ICA inspection. ***\n');

for k = 1:size(subjects, 2)
    subject = subjects(k);
    
    % make sure we preprocess only once per subject
    if any(prep_comp_subs(:) == subject.ppn)
        fprintf('\n*** Skipping for k=%d, sub-%02d (already preprocessed). ***\n', k, subject.ppn);
        continue
    end
    
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
    
    if input('Continue with next subject? (Y/N)', 's') ~= 'Y'
        break
    end
end

%% 