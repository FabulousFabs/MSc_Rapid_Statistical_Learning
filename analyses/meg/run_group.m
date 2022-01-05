% @Description: Runs all group-level analyses.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /home/common/matlab/fieldtrip/qsub;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;

ft_defaults;

rootdir = '/project/3018012.23/';
sourcemodel_loc = '/home/common/matlab/fieldtrip/template/sourcemodel/standard_sourcemodel3d8mm.mat';

subjects = helper_datainfo(rootdir);

%% compute overall TFRs that we use for visual inspection
group_tfr(subjects, rootdir);

% please note that at this stage the final TOI/FOI selection has to be done
% such that the scripts afterwards can be run only once. this was done
% explicitly in the following scripts for ease-of-use (to avoid long-winded
% functions computing any dynamically specified combinations)

%% compute clusters for selected TOIs/FOIs
group_tfr_theta(subjects, rootdir);
group_tfr_beta(subjects, rootdir);

% please note that at this stage the final source localisation TOI/FOIs
% should be taken from the results of the cluster-based permutation tests
% that were run in this step - again, for ease-of-use these will be
% hardcoded, albeit its ugliness; note that this also affects the use of
% qsub_run_subject_source!
% Please run run_subject_qsub_source.m before proceeding.

%% compute sources for selected TOIs/FOIs
group_source_theta(subjects, rootdir);
group_source_beta(subjects, rootdir);

%% compute roi fun for selected TOIs/FOIs/COIs
% please note that this requires some adjustment within the file (to
% enter the relevant contrasts of interest and so on) so please make
% sure that these are valid before proceeding.
% Please run run_subject_qsub_ROI.m before proceeding.
group_roi_theta(subjects, rootdir);