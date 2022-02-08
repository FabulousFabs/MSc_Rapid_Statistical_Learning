# Analysis scripts
These directories include all files for behavioural, MEG and combined analyses. For explanations, please refer to the paper as well as the scripts themselves (and comments therein). Below, we outline the general flow of analyses.

## Behavioural analysis
These are relatively straight forward and can be run as is (with minor changes to adjust path variables).

To reproduce results, run `run_MEG.r` and `run_4AFC.r` (in any order). In both cases, data will be aggregated from the prespecified directories using python, outlier analysis will be performed (using MAD), data will be inspected visually and models will be fit, validated and visualised.

## MEG analysis
These are split into preprocessing steps, subject-level steps and group-level steps. Consequently, scripts are grouped as `prep_*.m` (preprocessing steps), `subj_*.m` (subject-level steps), `group_*.m` (group-level steps) as well as `qsub_*.m` (subroutines for parallel computing on HPC), `helper_*.m` (general purpose functions) and `run_*.m` (entry points).

Note that before running any of these files, paths will have to be adjusted in any `run_*.m` file you want to compute.

### Preprocessing steps
To reproduce preprocessing steps, please make use of the sections in `run_preprocessing.m`.

The first section will run `prep_subject_before.m` (trial definitions, G3BR correction, demeaning, channel & trial rejection, filtering of muscular artefacts and downsampling to 400Hz), `prep_subject_ica.m` (ICA decomposition), `prep_subject_after.m` (visualisation of components and flagging), `prep_geom_realign.m` (MRI/Polhemus co-registration) and `prep_geom_segmentmri_and_leadfield.m` (segmentation of MRI, head models, source models, lead fields) for every participant. Note that this will keep track of subjects that have been preprocessed already and will skip them. To recompute these steps, please load and clear `prep_comp_subs` from `/processed/combined/preprocessing_completed.mat`.

The second section will run `group_trend.m` to generate several views of all data to check for trends that need to be addressed later. Outputs can be found in `/processed/combined/trends/`. Note that this step should be repeated, changing the qsub to be run to `qsub_subj_control_space.m` to visualise the alignments of MRI/MEG data, the outputs of which can be found in `/processed/combined/space/`.

The third and fourth sections will run and retrieve `qsub_subj_movement.m` in batch jobs. This will create movement regressors for analyses as well as visualisations of movement per participant for a final inclusion/exclusion decision that needs to be taken now. Graphical outputs can be found in `/processed/combined/movement/`.

### Subject-level steps
To reproduce these, please run all sections of `run_subject_qsub.m` (all TFRs). Note that the following two steps depend on ROI/FOI/TOI selections. As such, it is advisable to run them after completing the first step of `run_group.m` (where this is indicated explicitly). If you want to follow the analyses presented in the paper precisely, no changes need be implemented here, however. In that case, run `run_subject_qsub_source.m` (beamformers) and `run_subject_qsub_ROI.m` (ROI extraction).

### Group-level steps
To reproduce these, please open `run_group.m` and follow the sections and comments carefully. Note that any outputs at this stage can be found in `/results/`.
