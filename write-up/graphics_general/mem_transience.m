% @Description: Quick script for visualising memory transience/overfitting.

%% Preamble
clearvars; close all;

addpath /home/common/matlab/fieldtrip;
addpath /project/3018012.23;
addpath /project/3018012.23/git/analyses/meg;

ft_defaults;

rootdir = '/project/3018012.23/';

%% Generate some data
x = [0:0.1:1];
b0 = 4.8;
b1 = 1.5;
b2 = 1.9;
sigma1 = 2.3;
sigma2 = 1.2;

y_familiar = b0 .* x + b1 .* normrnd(0, sigma1, [1, numel(x)]);
y_novel = b0 .* x + b2 .* normrnd(0, sigma2, [1, numel(x)]);

%% Fit some polys
p_poly = polyfit(x, y_familiar, 9);
p_linear = polyfit(x, y_familiar, 1);

y_fit_poly = polyval(p_poly, x);
%y_fit_poly = y_familiar;
y_fit_linear = polyval(p_linear, x);

%y_mse_poly = immse(y_fit_poly, y_familiar);
y_mse_poly = immse(y_fit_poly, y_familiar) + 1;
y_mse_linear = immse(y_fit_linear, y_familiar);

%%
f1 = figure();
c = ft_colormap('viridis', 256);

subplot(1, 2, 1);
scatter(x, y_familiar, 'MarkerEdgeColor', c(64,:), 'MarkerFaceColor', c(64,:)); hold on
scatter(x, y_novel, 'MarkerEdgeColor', c(192,:), 'MarkerFaceColor', c(192,:)); hold on

fill([x, fliplr(x)], [y_fit_poly + (y_mse_poly/2), fliplr(y_fit_poly - (y_mse_poly/2))], c(128,:), 'FaceAlpha', 0.1, 'EdgeAlpha', 0.1); hold on
plot(x, y_fit_poly, 'Color', c(128,:));
ylim([-8 10]);
xlim([-0.2 1.2]);

subplot(1, 2, 2);
scatter(x, y_familiar, 'MarkerEdgeColor', c(64,:), 'MarkerFaceColor', c(64,:)); hold on
scatter(x, y_novel, 'MarkerEdgeColor', c(192,:), 'MarkerFaceColor', c(192,:)); hold on

fill([x, fliplr(x)], [y_fit_linear + (y_mse_linear/2), fliplr(y_fit_linear - (y_mse_linear/2))], c(128,:), 'FaceAlpha', 0.1, 'EdgeAlpha', 0.1); hold on
plot(x, y_fit_linear, 'Color', c(128,:));
ylim([-8 10]);
xlim([-0.2 1.2]);