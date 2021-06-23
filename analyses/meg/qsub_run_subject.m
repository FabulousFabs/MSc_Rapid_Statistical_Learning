% @Description: Function to run for for a qsub subject process.

function exit = qsub_run_subject(subject)
    addpath /home/common/matlab/fieldtrip/;
    addpath /project/3018012.23/;
    addpath /project/3018012.23/git/analyses/meg/;

    subj_tfr(subject);
    subj_tfr_evoked(subject);
    subj_tfr_btwn(subject);
    subj_tfr_evoked_btwn(subject);
    subj_source_theta_bf(subject);
    subj_source_beta_bf(subject);
    subj_source_beta_bf_btwn(subject);
    
    exit = true;
end