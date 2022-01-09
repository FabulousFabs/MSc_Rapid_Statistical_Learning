% @Description: Compute group-level theta/delta sources for visual inspection.

function group_source_theta(subjects, rootdir)
    delta_sources = {};
    delta_sources_early = {};
    delta_sources_late = {};

    delta_diff_L1 = {};
    delta_diff_L2 = {};
    delta_avg_VE = {};
    delta_avg_ST = {};

    for k = 1:numel(subjects)
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end

        load(fullfile(subjects(k).out, 'subj_source_delta_bf.mat'), 'sources', 'sources_early', 'sources_late');
        delta_sources{k} = sources;
        delta_sources_early{k} = sources_early;
        delta_sources_late{k} = sources_late;

        delta_diff_L1{k} = sources_late{1};
        delta_diff_L1{k}.pow = (sources_late{1}.pow - sources_late{2}.pow);

        delta_diff_L2{k} = sources_late{2};
        delta_diff_L2{k}.pow = (sources_late{3}.pow - sources_late{4}.pow);

        delta_avg_VE{k} = sources_late{1};
        delta_avg_VE{k}.pow = (sources_late{1}.pow + sources_late{3}.pow) ./ 2;

        delta_avg_ST{k} = sources_late{2};
        delta_avg_ST{k}.pow = (sources_late{2}.pow + sources_late{4}.pow) ./ 2;
    end

    delta_sources = cat(1, delta_sources{:}); % subject x condition
    delta_sources_early = cat(1, delta_sources_early{:}); % subject x condition
    delta_sources_late = cat(1, delta_sources_late{:}); % subject x condition

    delta_diff_L1 = delta_diff_L1(~cellfun('isempty', delta_diff_L1))';
    delta_diff_L2 = delta_diff_L2(~cellfun('isempty', delta_diff_L2))';
    delta_avg_VE = delta_avg_VE(~cellfun('isempty', delta_avg_VE))';
    delta_avg_ST = delta_avg_ST(~cellfun('isempty', delta_avg_ST))';

    delta_norm = {delta_diff_L1 delta_diff_L2 delta_avg_VE delta_avg_ST};
    delta_norm = cat(2, delta_norm{:});

    %%
    %allsources = [delta_sources_late delta_norm];
    allsources = delta_sources_early;

    %%
    load(sourcemodel_loc, 'sourcemodel');
    template_grid = sourcemodel;
    clear sourcemodel;

    %%
    for k = 1:numel(allsources)
        allsources{k}.inside = template_grid.inside;
        allsources{k}.pos = template_grid.pos;
        allsources{k}.dim = template_grid.dim;

        tmp = allsources{k}.pow;
        allsources{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        allsources{k}.pow(template_grid.inside, :, :) = tmp;
    end

    %%
    cfg = [];
    cfg.parameter = 'pow';
    cfg.method = 'analytic';
    cfg.correctm = 'no';
    cfg.statistic = 'ft_statfun_depsamplesT';
    cfg.tail = 0;

    nobs = size(allsources, 1);
    cfg.design = [
        ones(1, nobs)*1 ones(1, nobs)*2
        1:nobs 1:nobs
    ];
    cfg.ivar = 1;
    cfg.uvar = 2;

    %%
    stat_l1p1_l1p3 = ft_sourcestatistics(cfg, allsources{:,1}, allsources{:,2});
    stat_l2p2_l2p3 = ft_sourcestatistics(cfg, allsources{:,3}, allsources{:,4});
    stat_l1p1_l2p2 = ft_sourcestatistics(cfg, allsources{:,1}, allsources{:,3});
    stat_l1p3_l2p3 = ft_sourcestatistics(cfg, allsources{:,2}, allsources{:,4});
    %stat_diff_l1l2 = ft_sourcestatistics(cfg, allsources{:,5}, allsources{:,6});
    %stat_avg_vesta = ft_sourcestatistics(cfg, allsources{:,7}, allsources{:,8});

    %%
    stat_theta_l1d = ft_sourcestatistics(cfg, allsources{:,1}, allsources{:,2});


    %%
    mri = ft_read_mri(fullfile(rootdir, 'processed', 'combined', 'average305_t1_tal_lin.nii'));
    mri.coordsys = 'mni';

    %%
    cfg = [];
    cfg.parameter = 'stat';

    interp_l1p1_l1p3 = ft_sourceinterpolate(cfg, stat_l1p1_l1p3, mri);
    interp_l2p2_l2p3 = ft_sourceinterpolate(cfg, stat_l2p2_l2p3, mri);
    interp_l1p1_l2p2 = ft_sourceinterpolate(cfg, stat_l1p1_l2p2, mri);
    interp_l1p3_l2p3 = ft_sourceinterpolate(cfg, stat_l1p3_l2p3, mri);
    %interp_diff_l1l2 = ft_sourceinterpolate(cfg, stat_diff_l1l2, mri);
    %interp_avg_vesta = ft_sourceinterpolate(cfg, stat_avg_vesta, mri);

    %%
    interp_theta_l1d = ft_sourceinterpolate(cfg, stat_theta_l1d, mri);

    %%
    interp_l1p1_l1p3.nice_mask = helper_make_mask(interp_l1p1_l1p3.stat, [.5 .8], 'neg');
    interp_l2p2_l2p3.nice_mask = helper_make_mask(interp_l2p2_l2p3.stat, [.5 .8], 'pos');
    interp_l1p1_l2p2.nice_mask = helper_make_mask(interp_l1p1_l2p2.stat, [.5 .8], 'pos');
    interp_l1p3_l2p3.nice_mask = helper_make_mask(interp_l1p3_l2p3.stat, [.5 .8], 'pos');
    %interp_diff_l1l2.nice_mask = helper_make_mask(interp_diff_l1l2.stat, [.5 .8], 'neg');
    %interp_avg_vesta.nice_mask = helper_make_mask(interp_avg_vesta.stat, [.5 .8], 'pos');

    %%
    interp_theta_l1d.nice_mask = helper_make_mask(interp_theta_l1d.stat, [.5 .8], 'pos');

    %%
    atl = fullfile('/home', 'common', 'matlab', 'fieldtrip', 'template', 'atlas', 'aal', 'ROI_MNI_V4.nii');
    cfg = [];
    cfg.atlas = atl;
    cfg.funparameter = 'stat';
    cfg.method = 'ortho';
    cfg.funcolorlim = [-4 4];
    cfg.funcolormap = ft_colormap('*RdYlBu', 256);
    cfg.colorbar = 'yes';

    %% explore source space l1p1-l1p3
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_l1p1_l1p3);

    %%
    mask_pfc = helper_mask_ROI(mri, atl, {'Frontal_Sup_L', 'Frontal_Sup_R', 'Frontal_Sup_Medial_L', 'Frontal_Sup_Medial_R', 'Cingulum_Ant_L', 'Cingulum_Ant_R', 'Cingulum_Mid_L', 'Cingulum_Mid_R'});
    mask_hpc = helper_mask_ROI(mri, atl, {'Hippocampus_L', 'Hippocampus_R'});

    %% ACC/frontal
    f1 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l1p3, mask_pfc);
    ft_sourceplot(cfg, interp_l1p1_l1p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f1, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f1, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f1, fullfile(rootdir, 'results', 'source_delta_l1p1_l1p3_pfc.svg'), 'svg');
    saveas(f1, fullfile(rootdir, 'results', 'source_delta_l1p1_l1p3_pfc.png'), 'png');

    %% HPC
    f2 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l1p3, mask_hpc);
    ft_sourceplot(cfg, interp_l1p1_l1p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f2, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f2, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f2, fullfile(rootdir, 'results', 'source_delta_l1p1_l1p3_hpc.svg'), 'svg');
    saveas(f2, fullfile(rootdir, 'results', 'source_delta_l1p1_l1p3_hpc.png'), 'png');

    %%
    cfg = rmfield(cfg, 'location');

    %% explore source space l2p2-l2p3
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_l2p2_l2p3);

    %%
    mask_inf_tri = helper_mask_ROI(mri, atl, {'Frontal_Inf_Tri_L', 'Frontal_Inf_Tri_R'});
    mask_sup_fro = helper_mask_ROI(mri, atl, {'Frontal_Sup_L', 'Frontal_Sup_R', 'Frontal_Sup_Orb_L', 'Frontal_Sup_Orb_R', 'Frontal_Mid_L', 'Frontal_Mid_R', 'Frontal_Mid_Orb_L', 'Frontal_Mid_Orb_R'});

    %% inf tri l
    f3 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l2p2_l2p3, mask_inf_tri);
    ft_sourceplot(cfg, interp_l2p2_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f3, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f3, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f3, fullfile(rootdir, 'results', 'source_delta_l2p2_l2p3_tri.svg'), 'svg');
    saveas(f3, fullfile(rootdir, 'results', 'source_delta_l2p2_l2p3_tri.png'), 'png');

    %% sup fro
    f4 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l2p2_l2p3, mask_sup_fro);
    ft_sourceplot(cfg, interp_l2p2_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f4, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f4, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f4, fullfile(rootdir, 'results', 'source_delta_l2p2_l2p3_fro.svg'), 'svg');
    saveas(f4, fullfile(rootdir, 'results', 'source_delta_l2p2_l2p3_fro.png'), 'png');

    %%
    cfg = rmfield(cfg, 'location');

    %% explore source space l1p3-l2p3
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_l1p3_l2p3);

    %%
    mask_pfc2 = helper_mask_ROI(mri, atl, {'Frontal_Sup_L', 'Frontal_Sup_R', 'Frontal_Sup_Medial_L', 'Frontal_Sup_Medial_R', 'Cingulum_Ant_L', 'Cingulum_Ant_R', 'Cingulum_Mid_L', 'Cingulum_Mid_R', 'Caudate_L', 'Caudate_R'});
    mask_hpc2 = helper_mask_ROI(mri, atl, {'Hippocampus_L', 'Hippocampus_R', 'ParaHippocampal_L', 'ParaHippocampal_R'});

    %% pfc2
    f5 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p3_l2p3, mask_pfc2);
    ft_sourceplot(cfg, interp_l1p3_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f5, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f5, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f5, fullfile(rootdir, 'results', 'source_delta_l1p3_l2p3_pfc2.svg'), 'svg');
    saveas(f5, fullfile(rootdir, 'results', 'source_delta_l1p3_l2p3_pfc2.png'), 'png');

    %% hpc2
    f6 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p3_l2p3, mask_hpc2);
    ft_sourceplot(cfg, interp_l1p3_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f6, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f6, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f6, fullfile(rootdir, 'results', 'source_delta_l1p3_l2p3_hpc2.svg'), 'svg');
    saveas(f6, fullfile(rootdir, 'results', 'source_delta_l1p3_l2p3_hpc2.png'), 'png');

    %%
    cfg = rmfield(cfg, 'location');

    %% explore source space of differences l1-l2
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_diff_l1l2);
    % nothing of interest, really - pretty much exactly what we saw (but good
    % to confirm i guess) and we dont have the space to talk about this anymore

    %% explore source space of avg ve-sta
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_avg_vesta);

    %%
    mask_agpc = helper_mask_ROI(mri, atl, {'Angular_L', 'Angular_R', 'Precuneus_L', 'Precuneus_R'});

    %%
    f7 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_avg_vesta, mask_agpc);
    ft_sourceplot(cfg, interp_avg_vesta);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f7, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f7, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f7, fullfile(rootdir, 'results', 'source_delta_avg_vesta_agpc.svg'), 'svg');
    saveas(f7, fullfile(rootdir, 'results', 'source_delta_avg_vesta_agpc.png'), 'png');

    %% explore source space of early "theta" l1p1-l1p3
    % we're making this exploration plot the onus here because it's the only
    % real effect we'd want to plot i think
    cfg.maskparameter = 'nice_mask';
    f8 = figure('visible', 'off');
    ft_sourceplot(cfg, interp_theta_l1d);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f8, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f8, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f8, fullfile(rootdir, 'results', 'source_theta_l1p1_l1p3_pfc.svg'), 'svg');
    saveas(f8, fullfile(rootdir, 'results', 'source_theta_l1p1_l1p3_pfc.png'), 'png');

    %%
    clear f1;
    clear f2;
    clear f3;
    clear f4;
    clear f5;
    clear f6;
    clear f7;

    %%
    clear f8;

    %%
    save(fullfile(rootdir, 'results', 'group_source_delta.mat'));
end