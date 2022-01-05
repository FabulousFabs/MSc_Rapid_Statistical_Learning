% @Description: Loads cleaned MEG data.
% 
% INPUTS:
%   subject     - Subject
%
% OUTPUTS:
%   data        - Cleaned data

function [f, R, P] = helper_corrplot(x, y, x_lim, y_lim, x_lab, y_lab, t)
    mdl = fitlm(x, y);
    xpred = linspace(min(x), max(x), 200)';
    [ypred, yci] = predict(mdl, xpred);
    
    function d = d_d(p, A, B)
        v1 = A - B;
        v2 = p - A;
        m = [v1; v2];
        d = abs(det(m)) ./ sqrt(dot(v1, v1));
    end
    
    d_A = [xpred(1), ypred(1)];
    d_B = [xpred(end), ypred(end)];
    dist = arrayfun(@(xn, yn) d_d([xn, yn], d_A, d_B), x, y);
    
    f = figure; hold on
    scatter(x, y, 10, dist, 'o');
    ft_colormap('viridis', 512);
    xlim(x_lim);
    ylim(y_lim);
    title(t);
    h = fill_between(xpred, yci(:, 1), yci(:, 2));
    h.EdgeColor = 'none';
    h.FaceColor = [0 0 0];
    h.FaceAlpha = 0.2;
    plot(xpred, ypred, 'k-');
    [R, P] = corrcoef(x, y, 'rows', 'complete');

    p_t = 'n.s.';
    if P(1,2) <= 1e-3
        p_t = '***';
    elseif P(1,2) <= 1e-2
        p_t = '**';
    elseif P(1,2) <= 0.05
        p_t = '*';
    end

    text(x_lim(2) * 0.9, y_lim(2) * 0.9, sprintf('\\rho = %.2f', R(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontName', 'Roboto', 'FontSize', 8);
    %text(x_lim(2) * 0.9, y_lim(2) * 0.9, sprintf('p < %.2f', P(1,2)), 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontWeight', 'bold');
    text(x_lim(2) * 0.9, y_lim(2) * 0.95, p_t, 'HorizontalAlignment', 'center', 'Color', '#373737', 'FontName', 'Roboto', 'FontSize', 8);
    xlabel(x_lab);
    ylabel(y_lab);
    
    ax = gca; 
    ax.FontName = 'Roboto'; 
    ax.FontSize = 8;
end