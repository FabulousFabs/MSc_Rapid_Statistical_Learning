% @description: Run preprocessing of all behavioural data.

% setup
clearvars; close all;

rootdir = '/project/3018012.23/';
pwdir = fullfile(rootdir, 'git', 'analyses', 'behavioural');
outdir = fullfile(rootdir, 'processed', 'combined');

load(fullfile(outdir, 'MEG.mat'), 'data', 'descriptors');

%%
dummy = data.raw(data.raw.r ~= '-1', :);

dummy.indx = (1:size(dummy, 1))';
ppns = unique(dummy.ppn);
isout = zeros(size(dummy, 1), 1);

for i = 1:size(ppns)
    ind_l1p1 = dummy(dummy.ppn == ppns(i) & dummy.list == '1' & dummy.ver == 'true',:).indx;
    out_l1p1 = isoutlier(dummy(ind_l1p1,:).rt);
    isout(ind_l1p1) = out_l1p1;
    
    ind_l1p3 = dummy(dummy.ppn == ppns(i) & dummy.list == '1' & dummy.ver == 'false',:).indx;
    out_l1p3 = isoutlier(dummy(ind_l1p3,:).rt);
    isout(ind_l1p3) = out_l1p3;
    
    ind_l2p2 = dummy(dummy.ppn == ppns(i) & dummy.list == '2' & dummy.ver == 'true',:).indx;
    out_l2p2 = isoutlier(dummy(ind_l2p2,:).rt);
    isout(ind_l2p2) = out_l2p2;
    
    ind_l2p3 = dummy(dummy.ppn == ppns(i) & dummy.list == '2' & dummy.ver == 'false',:).indx;
    out_l2p3 = isoutlier(dummy(ind_l2p3,:).rt);
    isout(ind_l2p3) = out_l2p3;
end

cleaned = dummy(isout == 0, :);

%%
test = fitlme(cleaned, 'rt ~ -1 + i + list:ver + (1|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
test2 = fitlme(cleaned, 'rt ~ -1 + i + list:ver + (1|ppn) + (list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
test3 = fitlme(cleaned, 'rt ~ -1 + i + rep + list:ver + (1|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
test4 = fitlme(cleaned, 'rt ~ i + rep*list*ver + (1|ppn) + (1|t:def) + (1|ppn:id)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
dummy.cond = strings([size(dummy, 1), 1]);
l1p1 = dummy.list == '1' & dummy.ver == 'true';
l1p3 = dummy.list == '1' & dummy.ver == 'false';
l2p2 = dummy.list == '2' & dummy.ver == 'true';
l2p3 = dummy.list == '2' & dummy.ver == 'false';
dummy(l1p1,:).cond = repmat('L1P1', size(dummy(l1p1,:), 1), 1);
dummy(l1p3,:).cond = repmat('L1P3', size(dummy(l1p3,:), 1), 1);
dummy(l2p2,:).cond = repmat('L2P2', size(dummy(l2p2,:), 1), 1);
dummy(l2p3,:).cond = repmat('L2P3', size(dummy(l2p3,:), 1), 1);
dummy = convertvars(dummy, {'cond'}, 'categorical');

%%
[means, ppns] = helper_aggregate(dummy, 'ppn', 'rt', 'mean');
dummy.rtdm = dummy.rt;

for i = 1:size(ppns, 1)
    dummy(dummy.ppn == ppns(i),:).rtdm = dummy(dummy.ppn == ppns(i),:).rtdm - means(i);
end

%%
test = fitlme(dummy, 'rt ~ rep + cond + (1|ppn) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'reference');

%%
coefTest(test, [0 1 0 -1 0])
coefTest(test3, [0 0 1 0 -1 0])
coefTest(test, [0 0 1 0 -1])
coefTest(test3, [0 0 0 1 0 -1])
coefTest(test, [0 1 -1 0 0])
coefTest(test3, [0 0 1 -1 0 0])

%%
%model_rt_wo3 = fitlme(data.between, 'rt ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (-1+list:ver|ppn) + (1|rep) + (rep|list:ver:ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
test = fitlme(data.between, 'rt ~ -1 + list:ver + rep:list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (rep|ppn) + (1|t:def) + (-1+list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
%%
test = fitlme(data.between, 'rt ~ -1 + i + rep + list:ver + (1|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr) + (1|id:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
test2 = fitlme(data.between, 'rt ~ -1 + i + rep + list:ver + (1|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr) + (1|id:spkr) + (list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
test3 = fitlme(data.between, 'rt ~ -1 + i + rep + list:ver + (1|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr) + (1|id:spkr) + (rep:list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
%test4 = fitlme(data.between, 'rt ~ i + rep + list:ver + (1|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'effects'

%test = fitlme(data.between, 'rt ~ -1 + i + rep + list:ver + (1|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
data.between.fitted = fitted(test);
data.between.marginal = fitted(test, 'Conditional', false);

%%
addpath /home/common/matlab/fieldtrip;
ft_defaults;

fig = figure;
cmap = ft_colormap('viridis', 256);

[~, ~, Bs] = fixedEffects(test);
ppns = unique(data.between.ppn);

for i = 1:size(ppns, 1)
    l1ver = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.ver == 'true',:).fitted);
    l1non = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.ver == 'false',:).fitted);
    l2ver = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.ver == 'true',:).fitted);
    l2non = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.ver == 'false',:).fitted);
    
    
    p1 = plot([1 2], [l1ver l1non], '.-', 'Color', [cmap(64, 1:3) .3]); hold on
    p2 = plot([3.25 4.25], [l2ver l2non], '.-', 'Color', [cmap(192, 1:3) .3]); hold on
end

errorbar([0.85 2.15], [Bs.Estimate(5) Bs.Estimate(3)], [Bs.SE(5) Bs.SE(3)], 'o-', 'LineWidth', 2, 'Color', [cmap(64, 1:3)]); hold on
errorbar([3.1 4.4], [Bs.Estimate(6) Bs.Estimate(4)], [Bs.SE(6) Bs.SE(4)], 'o-', 'LineWidth', 2, 'Color', [cmap(192, 1:3)]); hold on

xlim([0.5 4.75]);
ylim([200 2000]);
title('MEG task');
ylabel('Reaction time [ms]');
text(1.5, 70, 'List_1', 'HorizontalAlignment', 'center', 'FontSize', 8);
text(3.75, 70, 'List_2', 'HorizontalAlignment', 'center', 'FontSize', 8);

ax = fig.CurrentAxes;
ax.FontName = 'Roboto';
ax.FontSize = 8;
ax.Box = 'off';
ax.XTick = [1 2 3.25 4.25];
ax.XTickLabel = {'Veridical' 'Statistical' 'Veridical' 'Statistical'};
ax.XTickLabelRotation = 0;
ax.XMinorTick = 'off';
ax.YGrid = 'on';
ax.XGrid = 'off';
ax.GridLineStyle = '-';
ax.Position = [.13 .11 .5 .815];
set(fig, 'GraphicsSmoothing', 'on');

%%
figure;

clear gca;

[~, ~, Bs] = fixedEffects(test);
ppns = unique(data.between.ppn);

sp1 = subplot(1, 2, 1);

errorbar([1 2], [Bs.Estimate(5) Bs.Estimate(3)], [Bs.SE(5) Bs.SE(3)], 'o-', 'LineWidth', 2, 'Color', '#77AC30'); hold on

for i = 1:size(ppns, 1)
    l1ver = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.ver == 'true',:).fitted);
    l1non = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.ver == 'false',:).fitted);
    
    plot([1 2], [l1ver l1non], '.-', 'Color', [0 0 0 0.25]); hold on
end

xlim([0.75 2.25]);
ylim([200 2000]);
title('List_1');

sp1.FontName = 'Roboto';
sp1.FontSize = 8;
sp1.Box = 'off';
sp1.XTick = [1 2];
sp1.XTickLabel = {'Veridical' 'Statistical'};
sp1.XTickLabelRotation = 45;
sp1.XMinorTick = 'off';
sp1.YGrid = 'on';
sp1.XGrid = 'off';
sp1.GridLineStyle = ':';

sp2 = subplot(1, 2, 2);

for i = 1:size(ppns, 1)
    l2ver = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.ver == 'true',:).fitted);
    l2non = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.ver == 'false',:).fitted);
    
    plot([1 2], [l2ver l2non], '.-', 'LineWidth', 1, 'Color', '#0072BD'); hold on
end

errorbar([1 2], [Bs.Estimate(6) Bs.Estimate(4)], [Bs.SE(6) Bs.SE(4)], '-', 'LineWidth', 2, 'Color', '#0072BD'); hold on

xlim([0.75 2.25]);
ylim([200 2000]);
title('List_2');

%set(gca, ...
%    'FontName',     'Roboto', ...
%    'FontSize',     8, ...
%    'Box',          'off', ...
%    'XTick',        [1 2], ...
%    'XTickLabel',   {'Veridical' 'Statistical'}, ...
%    'XMinorTick',   'off', ...
%    'YTickLabel',   {}, ...
%    'YGrid',        'on', ...
%    'XGrid',        'off', ...
%    'GridLineStyle',':');

sp2.FontName = 'Roboto';
sp2.FontSize = 8;
sp2.Box = 'off';
sp2.XTick = [1 2];
sp2.XTickLabel = {'Veridical' 'Statistical'};
sp2.XTickLabelRotation = 45;
sp2.XMinorTick = 'off';
sp2.YTickLabel = {};
sp2.YGrid = 'on';
sp2.XGrid = 'off';
sp2.GridLineStyle = ':';
sp2.YAxis.Visible = 'off';

sp1.Position = [.13 .11 .225 .815];
sp2.Position = [.355 .11 .225 .815];



%%
%coefTest(test, [0, 0, 1, 0, -1, 0])
%coefTest(test, [0, 0, 0, 1, 0, -1])
%coefTest(test, [0, 0, 1, -1, 0, 0])
%coefTest(test, [0, 0, 0, 0, 1, -1])
%coefTest(test, [1, 0, -1, 0, 0, 0, 0, 0])
%coefTest(test, [0, 1, 0, -1, 0, 0, 0, 0])
%coefTest(test, [1, -1, 0, 0, 0, 0, 0, 0])
%coefTest(test, [0, 0, 1, -1, 0, 0, 0, 0])
coefTest(test2, [0, 0, 1, 0, -1, 0])
coefTest(test2, [0, 0, 0, 1, 0, -1])
coefTest(test2, [0, 0, 1, -1, 0, 0])
coefTest(test2, [0, 0, 0, 0, 1, -1])

%%
coefTest(test, [0, 0, 0, 0, 1, -1, 0, 0])
coefTest(test, [0, 0, 0, 0, 0, 0, 1, -1])
coefTest(test, [0, 0, 0, 0, .5, -.5, .5, -.5])
coefTest(test, [0, 0, 0, 0, .5, .5, -.5, -.5])

%%
ppns = unique(data.raw.ppn);
j = zeros(size(data.raw, 1), 1);
w = zeros(size(ppns, 1), 60);

for i = 1:size(ppns, 1)
    entries = find(data.raw.ppn == ppns(i));
    
    for k = 1:size(entries, 1)
        t = data.raw(entries(k),:).id;
        w(i,t) = w(i,t) + 1;
        j(entries(k)) = w(i,t);
    end
end

%%
data.raw = convertvars(data.raw, {'c'}, 'categorical');
model = fitglme(data.raw, 'c ~ -1 + i + list:ver + (1|ppn) + (1|t:def)', 'Distribution', 'Binomial', 'BinomialSize', 1, 'DummyVarCoding', 'full');

%%
model_rt_wo = fitlme(data.between, 'rt ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (-1+list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
model_rt_wo2 = fitlme(data.between, 'rt ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (-1+list:ver|ppn) + (1|rep)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
model_rt_wo3 = fitlme(data.between, 'rt ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (-1+list:ver|ppn) + (1|rep) + (rep|list:ver:ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
model_rt_wo2 = fitlme(data.between, 'rt ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (1|list:ver:ppn) + (1|rep)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
coefTest(model_rt_wo2, [0, 1, 0, -1, 0])
coefTest(model_rt_wo2, [0, 0, 1, 0, -1])

%%
%model_rt = fitlme(data.between, 'rt ~ -1 + i + rep:list:ver + (1|ppn) + (rep:list:ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
model_rt = fitlme(data.between, 'rt ~ -1 + i + rep:list:ver + (i|ppn) + (1|rep:list:ver:ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');
model_rt2 = fitlme(data.between, 'rt ~ -1 + i + rep:list:ver + (i|ppn) + (1|rep:list:ver:ppn) + (i|t:def) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
coefTest(model_rt2, [0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0])
coefTest(model_rt2, [0, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8, 0, 1/8, 0, -1/8])

%%
data.between.marginal = fitted(model, 'Conditional', false);
data.between.fitted = fitted(model);

%%
data.between.repc = data.between.rep;
data.between = convertvars(data.between, {'repc'}, 'int16');
model_rt3 = fitlme(data.between, 'rt ~ -1 + i + repc + list:ver + (i|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
model_rt4 = fitlme(data.between, 'rt ~ -1 + i + list:ver + list:ver:repc + (i|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
coefTest(model_rt4, [0, 0, 0, 0, 0, 1, -1, 0, 0]);
coefTest(model_rt4, [0, 0, 0, 0, 0, 1, 0, -1, 0])
coefTest(model_rt4, [0, 0, 0, 0, 0, 0, 1, 0, -1])



%%
model_rtl = fitlme(data.between, 'rtl ~ -1 + i + list:ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');


%%
model = fitlme(data.between, 'rt ~ i + list*ver + (1|ppn) + (1|ppn:id) + (1|ppn:spkr) + (i|ppn) + (1|t:def) + (list*ver|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'effects');

%% visualise
data.between.marginal = fitted(model, 'Conditional', false);
data.between.fitted = fitted(model);


%%
model = fitlme(data.between, 'rt ~ -1 + i:list:ver + (1|ppn) + (i|ppn) + (1|t:def) + (1|ppn:id) + (1|ppn:spkr)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
data.between = dummy;

[B, n, s] = randomEffects(test);
ppns = unique(data.between.ppn);
ids = unique(data.between.id);
spkrs = unique(data.between.spkr);

wordeff = zeros(size(data.between, 1), 1);
spkreff = zeros(size(data.between, 1), 1);

for i = 1:size(ppns, 1)
    for j = 1:size(ids, 1)
        e = ones(nnz(data.between.ppn == ppns(i) & data.between.id == ids(j)), 1) .* B(find(strcmp(string(n.Group), 'ppn:id') & strcmp(string(n.Level), sprintf('%s %s', string(ppns(i)), string(ids(j))))));
        wordeff(data.between.ppn == ppns(i) & data.between.id == ids(j)) = e;
    end
    
    for j = 1:size(spkrs, 1)
        e = ones(nnz(data.between.ppn == ppns(i) & data.between.spkr == spkrs(j)), 1) .* B(find(strcmp(string(n.Group), 'ppn:spkr') & strcmp(string(n.Level), sprintf('%s %s', string(ppns(i)), string(spkrs(j))))));
        spkreff(data.between.ppn == ppns(i) & data.between.spkr == spkrs(j)) = e;
    end
end

%%
dummy.wordeff = wordeff;
dummy.spkreff = spkreff;

%%
scatter(dummy.wordeff, dummy.spkreff, '.');
[R, P] = corrcoef(dummy.wordeff, dummy.spkreff)

%%
dumb_test = fitlme(dummy, 'rt ~ id:spkr + (1|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'reference');

%% 

sel_l1p1 = dummy.list == '1' & dummy.ver == 'true';
sel_l1p3 = dummy.list == '1' & dummy.ver == 'false';
sel_l2p2 = dummy.list == '2' & dummy.ver == 'true';
sel_l2p3 = dummy.list == '2' & dummy.ver == 'false';

figure;

subplot(2, 2, 1);
x = (dummy(sel_l1p1,:).wordeff - mean(dummy(sel_l1p1,:).wordeff)) / std(dummy(sel_l1p1,:).wordeff);
y = (dummy(sel_l1p1,:).spkreff - mean(dummy(sel_l1p1,:).spkreff)) / std(dummy(sel_l1p1,:).spkreff);
scatter(x, y);
[R_l1p1, P_l1p1] = corrcoef(x, y)

subplot(2, 2, 2);
scatter(dummy(sel_l1p3,:).wordeff, dummy(sel_l1p3,:).spkreff);
[R_l1p3, P_l1p3] = corrcoef(dummy(sel_l1p3,:).wordeff, dummy(sel_l1p3,:).spkreff)

subplot(2, 2, 3);
scatter(dummy(sel_l2p2,:).wordeff, dummy(sel_l2p2,:).spkreff);
[R_l2p2, P_l2p2] = corrcoef(dummy(sel_l2p2,:).wordeff, dummy(sel_l2p2,:).spkreff)

subplot(2, 2, 4);
scatter(dummy(sel_l2p3,:).wordeff, dummy(sel_l2p3,:).spkreff);
[R_l2p3, P_l2p3] = corrcoef(dummy(sel_l2p3,:).wordeff, dummy(sel_l2p3,:).spkreff)

%%
[B, n, s] = randomEffects(model);
ppns = unique(data.between.ppn);
ids = unique(data.between.id);
spkrs = unique(data.between.spkr);

listeff = zeros(size(data.between, 1), 1);
vereff = zeros(size(data.between, 1), 1);

%%
%%
[~ ,~ , Bs] = fixedEffects(model);
%data.between.fitted = fitted(model, 'Conditional', false) - (Bs.Estimate(1) * data.between.i);
data.between.marginal = fitted(model, 'Conditional', false);
data.between.fitted = fitted(model);

%%
figure;

ppns = unique(data.between.ppn);

subplot(2, 2, 1);

%plot([1 1], [Bs.Estimate(4)-Bs.SE(4) Bs.Estimate(4)+Bs.SE(4)], '-'); hold on

for i = 1:size(ppns, 1)
    l1p1 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.pool == '1',:).marginal);
    l1p3 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.pool == '3',:).marginal);
    
    plot([1 2], [l1p1 l1p3], '.-'); hold on
end

xlim([0 3]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'veridical' 'statistical'});

subplot(2, 2, 2);

for i = 1:size(ppns, 1)
    l2p2 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.pool == '2',:).marginal);
    l2p3 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.pool == '3',:).marginal);
    
    plot([1 2], [l2p2 l2p3], '.--'); hold on
end

xlim([0 3]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'veridical' 'statistical'});

subplot(2, 2, 3);

%plot([1 1], [Bs.Estimate(4)-Bs.SE(4) Bs.Estimate(4)+Bs.SE(4)], '-'); hold on

for i = 1:size(ppns, 1)
    l1p1 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.pool == '1',:).fitted);
    l1p3 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '1' & data.between.pool == '3',:).fitted);
    
    plot([1 2], [l1p1 l1p3], '.--'); hold on
end

xlim([0 3]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'veridical' 'statistical'});

subplot(2, 2, 4);

for i = 1:size(ppns, 1)
    l2p2 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.pool == '2',:).fitted);
    l2p3 = mean(data.between(data.between.ppn == ppns(i) & data.between.list == '2' & data.between.pool == '3',:).fitted);
    
    plot([1 2], [l2p2 l2p3], '.--'); hold on
end

xlim([0 3]);
set(gca, 'XTick', [1 2], 'XTickLabel', {'veridical' 'statistical'});


%%
[B, n, s] = randomEffects(model);

%%
ppns = unique(data.between.ppn);
figure;

subplot(2, 1, 1);

for i = 1:size(ppns, 1)
    l1p1 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'list_1:ver_true'));
    l1p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'list_1:ver_false'));
       
    plot([1 2], [l1p1 l1p3], '.--'); hold on
end

xlim([-2 5]);


subplot(2, 1, 2);

for i = 1:size(ppns, 1)
    l2p2 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'list_2:ver_true'));
    l2p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'list_2:ver_false'));
         
    plot([1 2], [l2p2 l2p3], 'o-'); hold on
end

xlim([-2 5]);

%%
coefTest(model_rt, [0 .5 .5 -.5 -.5])
coefTest(model_rt, [0 1 0 -1 0])
coefTest(model_rt, [0 0 1 0 -1])

%%
coefTest(model_rt, [0 .5 -.5 .5 -.5])
%coefTest(model_rt, [0 1 -1 0 0 ]);
%coefTest(model_rt, [0 0 0 1 -1])