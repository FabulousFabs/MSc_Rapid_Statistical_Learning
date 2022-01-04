% @Description: Compute group-level beta sources for visual inspection.

function group_source_beta(subjects, rootdir)
    beta_sources = {};
    beta_sources_early = {};
    beta_sources_late = {};

    beta_diff_L1 = {};
    beta_diff_L2 = {};
    
    beta_early_diff_L1 = {};
    beta_early_diff_L2 = {};
    
    beta_late_diff_L1 = {};
    beta_late_diff_L2 = {};
    
    
    for k = 1:numel(subjects)
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end

        load(fullfile(subjects(k).out, 'subj_source_beta_bf_prompt.mat'), 'sources', 'sources_early', 'sources_late');
        beta_sources{k} = sources;
        beta_sources_early{k} = sources_early;
        beta_sources_late{k} = sources_late;
        
        beta_diff_L1{k} = sources{1};
        beta_diff_L1{k}.pow = (sources{1}.pow - sources{2}.pow);

        beta_diff_L2{k} = sources{2};
        beta_diff_L2{k}.pow = (sources{3}.pow - sources{4}.pow);
        
        beta_early_diff_L1{k} = sources_early{1};
        beta_early_diff_L1{k}.pow = (sources_early{1}.pow - sources_early{2}.pow);
        
        beta_early_diff_L2{k} = sources_early{3};
        beta_early_diff_L2{k}.pow = (sources_early{3}.pow - sources_early{4}.pow);
        
        beta_late_diff_L1{k} = sources_late{1};
        beta_late_diff_L1{k}.pow = (sources_late{1}.pow - sources_late{2}.pow);
        
        beta_late_diff_L2{k} = sources_late{3};
        beta_late_diff_L2{k}.pow = (sources_late{3}.pow - sources_late{4}.pow);
    end

    beta_sources = cat(1, beta_sources{:}); % subject x condition
    beta_sources_early = cat(1, beta_sources_early{:}); % subject x condition
    beta_sources_late = cat(1, beta_sources_late{:}); % subject x condition
    
    beta_diff_L1 = beta_diff_L1(~cellfun('isempty', beta_diff_L1))';
    beta_diff_L2 = beta_diff_L2(~cellfun('isempty', beta_diff_L2))';
    
    beta_early_diff_L1 = beta_early_diff_L1(~cellfun('isempty', beta_early_diff_L1))';
    beta_early_diff_L2 = beta_early_diff_L2(~cellfun('isempty', beta_early_diff_L2))';
    
    beta_late_diff_L1 = beta_late_diff_L1(~cellfun('isempty', beta_late_diff_L1))';
    beta_late_diff_L2 = beta_late_diff_L2(~cellfun('isempty', beta_late_diff_L2))';

    %%
    allsources = [beta_sources beta_diff_L1 beta_diff_L2];
    allsources_early = [beta_sources_early beta_early_diff_L1 beta_early_diff_L2];
    allsources_late = [beta_sources_late beta_late_diff_L1 beta_late_diff_L2];

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
    
    for k = 1:numel(allsources_early)
        allsources_early{k}.inside = template_grid.inside;
        allsources_early{k}.pos = template_grid.pos;
        allsources_early{k}.dim = template_grid.dim;

        tmp = allsources_early{k}.pow;
        allsources_early{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        allsources_early{k}.pow(template_grid.inside, :, :) = tmp;
    end
    
    for k = 1:numel(allsources_late)
        allsources_late{k}.inside = template_grid.inside;
        allsources_late{k}.pos = template_grid.pos;
        allsources_late{k}.dim = template_grid.dim;

        tmp = allsources_late{k}.pow;
        allsources_late{k}.pow = nan(size(template_grid.pos, 1), size(tmp, 2), size(tmp, 3));
        allsources_late{k}.pow(template_grid.inside, :, :) = tmp;
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
    stat_l1p1_l1p3 = ft_sourcestatistics(cfg, allsources_late{:,1}, allsources_late{:,2});
    stat_l2p2_l2p3 = ft_sourcestatistics(cfg, allsources{:,3}, allsources{:,4});
    stat_l1p1_l2p2 = ft_sourcestatistics(cfg, allsources_late{:,1}, allsources_late{:,3});
    stat_l1p3_l2p3 = ft_sourcestatistics(cfg, allsources_late{:,2}, allsources_late{:,4});
    stat_diff_l1l2 = ft_sourcestatistics(cfg, allsources{:,5}, allsources{:,6});

    %%
    mri = ft_read_mri(fullfile(rootdir, 'processed', 'combined', 'average305_t1_tal_lin.nii'));
    mri.coordsys = 'mni';
    
    %%
    %mri = ft_read_mri(fullfile('/home', 'common', 'matlab', 'spm12', 'canonical', 'avg152T1.nii'));
    %mri.coordsys = 'mni';

    %%
    cfg = [];
    cfg.parameter = 'stat';

    interp_l1p1_l1p3 = ft_sourceinterpolate(cfg, stat_l1p1_l1p3, mri);
    interp_l2p2_l2p3 = ft_sourceinterpolate(cfg, stat_l2p2_l2p3, mri);
    interp_l1p1_l2p2 = ft_sourceinterpolate(cfg, stat_l1p1_l2p2, mri);
    interp_l1p3_l2p3 = ft_sourceinterpolate(cfg, stat_l1p3_l2p3, mri);
    interp_diff_l1l2 = ft_sourceinterpolate(cfg, stat_diff_l1l2, mri);

    %%
    interp_l1p1_l1p3.nice_mask = helper_make_mask(interp_l1p1_l1p3.stat, [.5 .8], 'neg');
    interp_l2p2_l2p3.nice_mask = helper_make_mask(interp_l2p2_l2p3.stat, [.5 .8], 'neg');
    interp_l1p1_l2p2.nice_mask = helper_make_mask(interp_l1p1_l2p2.stat, [.5 .8], 'neg');
    interp_l1p3_l2p3.nice_mask = helper_make_mask(interp_l1p3_l2p3.stat, [.5 .8], 'pos');
    interp_l1p3_l2p3.nice_mask2 = helper_make_mask(interp_l1p3_l2p3.stat, [.3 .6], 'pos');
    interp_diff_l1l2.nice_mask = helper_make_mask(interp_diff_l1l2.stat, [.5 .8], 'neg');

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
    mask_ro = helper_mask_ROI(mri, atl, {'Angular_L', 'Angular_R', 'SupraMarginal_L', 'SupraMarginal_R', 'Temporal_Sup_R'});
    mask_tf = helper_mask_ROI(mri, atl, {'Frontal_Sup_R', 'Frontal_Inf_Oper_R', 'Rolandic_R'});
    
    %%
    f1 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l1p3, mask_ro);
    ft_sourceplot(cfg, interp_l1p1_l1p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f1, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f1, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f1, fullfile(rootdir, 'results', 'source_beta_l1p1_l1p3_ro.svg'), 'svg');
    saveas(f1, fullfile(rootdir, 'results', 'source_beta_l1p1_l1p3_ro.png'), 'png');

    %%
    f2 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l1p3, mask_tf);
    ft_sourceplot(cfg, interp_l1p1_l1p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f2, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f2, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f2, fullfile(rootdir, 'results', 'source_beta_l1p1_l1p3_tf.svg'), 'svg');
    saveas(f2, fullfile(rootdir, 'results', 'source_beta_l1p1_l1p3_tf.png'), 'png');

    %%
    cfg = rmfield(cfg, 'location');
    
    %% explore source space l2p2-l2p3
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_l2p2_l2p3);
    
    %%
    mask_ct = helper_mask_ROI(mri, atl, {'Rolandic_Oper_L', 'Rolandic_Oper_R', 'Postcentral_L', 'Postcentral_R'});
    
    %%
    f3 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l2p2_l2p3, mask_ct);
    ft_sourceplot(cfg, interp_l2p2_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f3, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f3, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f3, fullfile(rootdir, 'results', 'source_beta_l2p2_l2p3_ct.svg'), 'svg');
    saveas(f3, fullfile(rootdir, 'results', 'source_beta_l2p2_l2p3_ct.png'), 'png');
    
    %%
    cfg = rmfield(cfg, 'location');
    
    %% explore source space l1p1-l2p2
    cfg.maskparameter = 'nice_mask';
    ft_sourceplot(cfg, interp_l1p1_l2p2);
    
    %%
    mask_ti = helper_mask_ROI(mri, atl, {'Insula_L', 'Insula_R', 'Frontal_Inf_Oper_L', 'Frontal_Inf_Oper_R', 'Putamen_L', 'Putamen_R', 'Pallidum_L', 'Pallidum_R'});
    mask_om = helper_mask_ROI(mri, atl, {'SupraMarginal_L', 'SupraMarginal_R', 'Angular_L', 'Angular_R'});
    
    %%
    f4 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l2p2, mask_ti);
    ft_sourceplot(cfg, interp_l1p1_l2p2);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f4, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f4, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f4, fullfile(rootdir, 'results', 'source_beta_l1p1_l2p2_ti.svg'), 'svg');
    saveas(f4, fullfile(rootdir, 'results', 'source_beta_l1p1_l2p2_ti.png'), 'png');
    
    %%
    f5 = figure('visible', 'off');
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p1_l2p2, mask_om);
    ft_sourceplot(cfg, interp_l1p1_l2p2);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f5, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f5, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f5, fullfile(rootdir, 'results', 'source_beta_l1p1_l2p2_om.svg'), 'svg');
    saveas(f5, fullfile(rootdir, 'results', 'source_beta_l1p1_l2p2_om.png'), 'png');
    
    %%
    cfg = rmfield(cfg, 'location');
    
    %% explore source space l1p3-l2p3
    ft_sourceplot(cfg, interp_l1p3_l2p3);
    
    %% 
    mask_til = helper_mask_ROI(mri, atl, {'Insula_L', 'Frontal_Inf_Oper_L', 'Temporal_Sup_L', 'Temporal_Mid_L', 'Temporal_Inf_L', 'Parietal_Sup_L', 'Postcentral_L', 'Parietal_Mid_L', 'Angular_L', 'SupraMarginal_L'});
    
    %% explore source space l1p3-l2p3
    cfg.maskparameter = 'nice_mask';
    % actually, we're going to do this slightly differently here.
    % it's a little bit awkward because somehow there's a pretty massive
    % right-lateralised effect here that's substantially stronger than the
    % its ipsilateral counterpart
    f6 = figure('visible', 'off');
    ft_sourceplot(cfg, interp_l1p3_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f6, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f6, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f6, fullfile(rootdir, 'results', 'source_beta_l1p3_l2p3_rt.svg'), 'svg');
    saveas(f6, fullfile(rootdir, 'results', 'source_beta_l1p3_l2p3_rt.png'), 'png');
    
    %%
    f7 = figure('visible', 'off');
    cfg.maskparameter = 'nice_mask2';
    [~, cfg.location] = helper_peak_in_ROI(interp_l1p3_l2p3, mask_til);
    ft_sourceplot(cfg, interp_l1p3_l2p3);
    ax = gca;
    ax.FontName = 'Roboto';
    ax.FontSize = 8;
    set(findall(f7, '-property', 'FontName'), 'FontName', 'Roboto');
    set(findall(f7, '-property', 'FontSize'), 'FontSize', 8);
    saveas(f7, fullfile(rootdir, 'results', 'source_beta_l1p3_l2p3_til.svg'), 'svg');
    saveas(f7, fullfile(rootdir, 'results', 'source_beta_l1p3_l2p3_til.png'), 'png');
    
    %%
    cfg = rmfield(cfg, 'location');
    
    %%
    clear f1;
    clear f2;
    clear f3;
    clear f4;
    clear f5;
    clear f6;
    clear f7;
    
    %%
    save(fullfile(rootdir, 'results', 'group_source_beta.mat'));
end