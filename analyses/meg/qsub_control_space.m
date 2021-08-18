% @Description: Compute movement indicators and the corresponding 
% translations/rotations for a subject.

function exit = qsub_control_space(subjects, rootdir)
    addpath /home/common/matlab/fieldtrip/;
    addpath /project/3018012.23/;
    addpath /project/3018012.23/git/analyses/meg/;
    
    
    for k = 1:size(subjects, 2)
        subject = subjects(k);
        
        if subject.include ~= true
            continue;
        end
        
        load(fullfile(subject.out, 'geom-leadfield-mni-8mm-megchans.mat'), 'headmodel', 'leadfield');

        f = figure('visible', 'off'); hold on
        ft_plot_headmodel(headmodel, 'edgecolor', 'none', 'facecolor', 'b', 'facealpha', 0.6);
        ft_plot_mesh(leadfield.pos(leadfield.inside,:));
        view([-153 0]);
        saveas(f, fullfile(rootdir, 'processed', 'combined', 'space', sprintf('sub-%02d.png', subject.ppn)), 'png');

    end
end