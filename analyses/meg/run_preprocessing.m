% @Description: Batch graphical preprocessing of subject data.

clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

progressdir = '/project/3018012.23/processed/combined/';
progressf = 'preprocessing_completed.mat';
load(fullfile(progressdir, progressf), 'prep_comp_subs');

subjects = helper_datainfo(rootdir);

for k = 1:size(subjects)
    subject = subjects(k);
    
    if any(prep_comp_subs(:) == subject.ppn)
        continue
    end
    
    % ideally, I would want to run the ICAs as individual qsubs but given
    % that we're not scanning fast enough due to all the issues that have
    % been going on, that won't be an efficient use of our time. instead,
    % we're running it sequentially here.
    % create another graphical matlab qsub to compute stuff in the mean
    % time.
    
    prep_subject_before(subject);
    prep_subject_ica(subject);
    
    fprintf('*** Please jot down bad comps and reasons now. ***\n');
    prep_subject_after(subject);
    
    badcomps = [];
    badcomps_reasons = {};
    
    while 1
        comp = input('Which component should be flagged bad? (<0 to exit)');
        
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
