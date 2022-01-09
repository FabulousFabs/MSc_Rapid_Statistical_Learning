% @Description: Function to run for for a qsub subject process.

function exit = qsub_run_subject_ROI(subject)
    addpath /home/common/matlab/fieldtrip/;
    addpath /project/3018012.23/;
    addpath /project/3018012.23/git/analyses/meg/;
    
    if subject.ppn == 2 || subject.ppn == 32
        exit = true;
        return;
    end
    
    subj_source_delta_ROI(subject);
    subj_source_beta_ROI(subject);
    
    exit = true;
end