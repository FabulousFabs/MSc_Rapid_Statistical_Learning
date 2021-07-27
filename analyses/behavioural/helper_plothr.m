% @Description: Plot a hit rate stat.
%
% INPUTS:
%   x       - X-values
%   y       - Y-values
%   xlab    - Labels for x-values

function helper_plothr(x, y, xlab)
    figure;
    yline(1, '-r', 'ceiling'); hold on
    yline(mean(y), '-', 'mu'); hold on
    yline(mean(y)+std(y), '--g', '+1sd'); hold on
    yline(mean(y)-std(y), '--g', '-1sd'); hold on
    yline(mean(y)+2*std(y)', '--y', '+2sd'); hold on
    yline(mean(y)-2*std(y)', '--y', '-2sd'); hold on
    plot(y, '.');
    ylim([0 1.05]);
    set(gca, 'XTick', [1:numel(x)], 'XTickLabel', x);
    title(sprintf('Learning outcome by %s.', xlab));
    xlabel(xlab);
    ylabel('Hit rate');
end

