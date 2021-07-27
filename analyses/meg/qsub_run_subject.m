% @Description: Function to run for for a qsub subject process.

function exit = qsub_run_subject(rootdir, subject)
    addpath /home/common/matlab/fieldtrip/;
    addpath /project/3018012.23/;
    addpath /project/3018012.23/git/analyses/meg/;

    subj_tfr(rootdir, subject);
    subj_tfr_evoked(rootdir, subject);
    subj_tfr_btwn(rootdir, subject);
    subj_tfr_evoked_btwn(rootdir, subject);
    
    if subject.ppn == 32
        exit = true;
        return;
    end
    
    subj_source_theta_bf(subject);
    subj_source_beta_bf(subject);
    subj_source_beta_bf_btwn(subject);
    
    exit = true;
end