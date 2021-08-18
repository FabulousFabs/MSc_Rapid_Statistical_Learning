% @Description: Compute group-level TFRs for visual inspection.

function group_tfr(subjects, rootdir)
    % collect all data
    fprintf('\n*** Aggregating data across subjects. ***\n');
    
    ind_allfreqs = {};
    evo_allfreqs = {};
    prm_allfreqs = {};
    
    for k = 1:size(subjects, 2)
        % make sure we include only data from participants where we made
        % the decision to include their data in analyses
        if subjects(k).include ~= true
            fprintf('\n*** Excluding k=%d for sub-%02d. *** \n', k, subjects(k).ppn);
            continue
        end
        
        load(fullfile(subjects(k).out, 'subj_tfr.mat'), 'freqs');
        ind_allfreqs{k} = freqs;
        clear freqs;
        
        load(fullfile(subjects(k).out, 'subj_tfr_evoked.mat'), 'freqs');
        evo_allfreqs{k} = freqs;
        clear freqs;
        
        load(fullfile(subjects(k).out, 'subj_tfr_prompt.mat'), 'freqs');
        prm_allfreqs{k} = freqs;
        clear freqs;
    end
    
    ind_allfreqs = cat(1, ind_allfreqs{:});
    evo_allfreqs = cat(1, evo_allfreqs{:});
    prm_allfreqs = cat(1, prm_allfreqs{:});
    
    
    % compute GAs
    fprintf('\n*** Computing grand averages. ***\n');
    
    ga_ind = ft_freqgrandaverage([], ind_allfreqs{:,:});
    ga_evo = ft_freqgrandaverage([], evo_allfreqs{:,:});
    ga_prm = ft_freqgrandaverage([], prm_allfreqs{:,:});
    
    
    % collapse channels
    fprintf('\n*** Averaging over channels. ***\n');
    
    cfg = [];
    cfg.avgovrchan = 'yes';
    
    ga_ind = ft_selectdata(cfg, ga_ind);
    ga_evo = ft_selectdata(cfg, ga_evo);
    ga_prm = ft_selectdata(cfg, ga_prm);
    
    
    % interpolate data for visuals
    fprintf('\n*** Interpolating data for smooth visuals. ***\n');
    
    res = 512;
    
    main_time = linspace(min(ga_ind.time), max(ga_ind.time), res);
    prm_time = linspace(min(ga_prm.time), max(ga_prm.time), res);
    all_freq = linspace(min(ga_ind.freq), max(ga_ind.freq), res);
    chanax = 1:numel(ga_ind.label);
    
    [main_chan_grid_orig, main_freq_grid_orig, main_time_grid_orig] = ndgrid(chanax, ga_ind.freq, ga_ind.time);
    [prom_chan_grid_orig, prom_freq_grid_orig, prom_time_grid_orig] = ndgrid(chanax, ga_prm.freq, ga_prm.time);

    
    [main_chan_grid_interp, main_freq_grid_interp, main_time_grid_interp] = ndgrid(chanax, all_freq, main_time);
    [prom_chan_grid_interp, prom_freq_grid_interp, prom_time_grid_interp] = ndgrid(chanax, all_freq, prm_time);
    
    ind_F = griddedInterpolant(main_chan_grid_orig, main_freq_grid_orig, main_time_grid_orig, ga_ind.powspctrm);
    ga_ind.powspctrm = ind_F(main_chan_grid_interp, main_freq_grid_interp, main_time_grid_interp);
    ga_ind.time = main_time;
    ga_ind.freq = all_freq;
    
    evo_F = griddedInterpolant(main_chan_grid_orig, main_freq_grid_orig, main_time_grid_orig, ga_evo.powspctrm);
    ga_evo.powspctrm = evo_F(main_chan_grid_interp, main_freq_grid_interp, main_time_grid_interp);
    ga_evo.time = main_time;
    ga_evo.freq = all_freq;
    
    prm_F = griddedInterpolant(prom_chan_grid_orig, prom_freq_grid_orig, prom_time_grid_orig, ga_prm.powspctrm);
    ga_prm.powspctrm = prm_F(prom_chan_grid_interp, prom_freq_grid_interp, prom_time_grid_interp);
    ga_prm.time = prm_time;
    ga_prm.freq = all_freq;
    
    
    % visualise main
    fprintf('\n*** Creating main plots. ***\n');
    
    
    % induced activity, main TOI
    fprintf('\n- Induced activity, main TOI.\n');
    
    f1 = figure('visible', 'off');
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.baselinetype = 'absolute';
    cfg.baseline = [-0.5 -0.25];
    cfg.interactive = 'no';
    cfg.gridscale = 96;
    cfg.colormap = ft_colormap('*RdYlBu', 256);
    cfg.colorbar = 'no';
    ft_singleplotTFR(cfg, ga_ind);
    title(''); 
    xlabel('Time (s)', 'FontWeight', 'bold'); 
    ylabel('Frequency (Hz)', 'FontWeight', 'bold'); 
    ax = gca; 
    ax.FontName = 'Roboto'; 
    ax.FontSize = 8;
    ax.Position = ax.Position + [0.0 -0.04 0.0 0.0];
    c = colorbar('northoutside');
    c.Label.String = 'Power (z-score)';
    c.Label.FontName = 'Roboto';
    c.Label.FontWeight = 'bold';
    c.Label.FontSize = 8;
    c.Position(3) = c.Position(3) * 0.5;
    c.Position(4) = c.Position(4) * 0.5;
    c.Position(1) = c.Position(1) + c.Position(3) * 0.5;
    c.Position(2) = c.Position(2) + 0.13;
    rectangle('Position', [0.1 1 0.2 6], 'EdgeColor', '#373737'); % rect theta
    rectangle('Position', [0.5 1 0.3 3], 'EdgeColor', '#373737'); % rect delta
    rectangle('Position', [0.6 20 0.2 3], 'EdgeColor', '#373737'); % rect beta1
    text(0.2, 4, '\theta', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    text(0.65, 2.5, '\delta', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    text(0.7, 21.5, '\beta_{1}', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    saveas(f1, fullfile(rootdir, 'results', 'tfr_ind_main.svg'), 'svg');
    saveas(f1, fullfile(rootdir, 'results', 'tfr_ind_main.png'), 'png');
    
    
    % evoked activity, main TOI
    fprintf('\n- Evoked activity, main TOI.\n');
    
    f2 = figure('visible', 'off');
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.baselinetype = 'zscore';
    cfg.baseline = [-0.5 -0.25];
    cfg.interactive = 'no';
    cfg.gridscale = 96;
    cfg.colormap = ft_colormap('*RdYlBu', 256);
    cfg.colorbar = 'no';
    ft_singleplotTFR(cfg, ga_evo);
    title(''); 
    xlabel('Time (s)', 'FontWeight', 'bold'); 
    ylabel('Frequency (Hz)', 'FontWeight', 'bold'); 
    ax = gca; 
    ax.FontName = 'Roboto'; 
    ax.FontSize = 8;
    ax.Position = ax.Position + [0.0 -0.04 0.0 0.0];
    c = colorbar('northoutside');
    c.Label.String = 'Power (z-score)';
    c.Label.FontName = 'Roboto';
    c.Label.FontWeight = 'bold';
    c.Label.FontSize = 8;
    c.Position(3) = c.Position(3) * 0.5;
    c.Position(4) = c.Position(4) * 0.5;
    c.Position(1) = c.Position(1) + c.Position(3) * 0.5;
    c.Position(2) = c.Position(2) + 0.13;
    rectangle('Position', [0.1 1 0.2 6], 'EdgeColor', '#373737'); % rect theta
    rectangle('Position', [0.5 1 0.3 3], 'EdgeColor', '#373737'); % rect delta
    text(0.2, 4, '\theta', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    text(0.65, 2.5, '\delta', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    saveas(f2, fullfile(rootdir, 'results', 'tfr_evo_main.svg'), 'svg');
    saveas(f2, fullfile(rootdir, 'results', 'tfr_evo_main.png'), 'png');
    
    
    % induced activity, prompt TOI
    fprintf('\n- Induced activity, prompt TOI.\n');
    
    f3 = figure('visible', 'off');
    cfg = [];
    cfg.parameter = 'powspctrm';
    cfg.baselinetype = 'absolute';
    cfg.baseline = [-.5 -.25];
    cfg.interactive = 'no';
    cfg.gridscale = 96;
    cfg.colormap = ft_colormap('*RdYlBu', 256);
    cfg.colorbar = 'no';
    ft_singleplotTFR(cfg, ga_prm);
    title(''); 
    xlabel('Time (s)', 'FontWeight', 'bold'); 
    ylabel('Frequency (Hz)', 'FontWeight', 'bold'); 
    ax = gca; 
    ax.FontName = 'Roboto'; 
    ax.FontSize = 8;
    ax.Position = ax.Position + [0.0 -0.04 0.0 0.0];
    c = colorbar('northoutside');
    c.Label.String = 'Power (z-score)';
    c.Label.FontName = 'Roboto';
    c.Label.FontWeight = 'bold';
    c.Label.FontSize = 8;
    c.Position(3) = c.Position(3) * 0.5;
    c.Position(4) = c.Position(4) * 0.5;
    c.Position(1) = c.Position(1) + c.Position(3) * 0.5;
    c.Position(2) = c.Position(2) + 0.13;
    rectangle('Position', [0.3 18 0.3 4], 'EdgeColor', '#373737'); % rect beta2
    text(0.45, 20, '\beta_{2}', 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    saveas(f3, fullfile(rootdir, 'results', 'tfr_prm_iti.svg'), 'svg');
    saveas(f3, fullfile(rootdir, 'results', 'tfr_prm_iti.png'), 'png');
end