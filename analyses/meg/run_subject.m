% @Description: Runs preprocessing for a subject.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;

ft_defaults;

rootdir = '/project/3018012.23/';

%% Select participant
subjects = helper_datainfo(rootdir);
sid = 2;

%% Compute TFRs (evoked)
[freqs, conds] = subj_tfr_evoked(subjects(sid));

%% MLF32/31; MLT13
cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.layout = 'CTF275.lay';
figure; ft_multiplotTFR(cfg, freqs{4});

%%
cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.channel = 'MLT13';
figure; ft_singleplotTFR(cfg, freqs{4});

%%
contrast_L1 = freqs{1};
%contrast_L1.powspctrm = (freqs{1}.powspctrm - freqs{2}.powspctrm) ./ (freqs{1}.powspctrm + freqs{2}.powspctrm);
contrast_L1.powspctrm = (freqs{1}.powspctrm - freqs{2}.powspctrm);

cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.channel = 'MLF32';
figure; ft_singleplotTFR(cfg, contrast_L1);

cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.channel = 'MLT13';
figure; ft_singleplotTFR(cfg, contrast_L1);

contrast_L2 = freqs{3};
%contrast_L2.powspctrm = (freqs{3}.powspctrm - freqs{4}.powspctrm) ./ (freqs{3}.powspctrm + freqs{4}.powspctrm);
contrast_L2.powspctrm = (freqs{3}.powspctrm - freqs{4}.powspctrm);

cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.channel = 'MLF32';
figure; ft_singleplotTFR(cfg, contrast_L2);

cfg = [];
cfg.baseline = [-0.5 -0.1];
cfg.zlim = [-3e-27 3e-27];
cfg.baselinetype = 'absolute';
cfg.channel = 'MLT13';
figure; ft_singleplotTFR(cfg, contrast_L2);

%%
