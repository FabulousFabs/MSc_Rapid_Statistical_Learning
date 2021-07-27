% @description: Run preprocessing of all behavioural data.

% setup
clearvars; close all;

rootdir = '/project/3018012.23/';
pwdir = fullfile(rootdir, 'git', 'analyses', 'behavioural');
outdir = fullfile(rootdir, 'processed', 'combined');

load(fullfile(outdir, '4AFC.mat'), 'data', 'descriptors');

%%
[models, best] = helper_lmebestfit(data.between, 'rt ~ -1 + i + rep + list:pool', ...
                                                {'(1|ppn:spkr)'; ...
                                                 '(1|ppn:id)'; ...
                                                 '(1|id:spkr)'; ...
                                                 '(1|rep)'; ...
                                                 '(1|ppn)'; ...
                                                 '(rep|ppn)'; ...
                                                 '(i|ppn)'; ...
                                                 '(loc|ppn)'; ...
                                                 '(1|list:pool:ppn)'});

%%
model = fitlme(data.between, 'rt ~ -1 + i + list:pool:rep + (-i+i|ppn) + (1|loc:ppn) + (1|ppn:id) + (1|ppn:spkr) + (1|id:spkr) + (1|list:pool:rep:ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full');

%%
[models4, best4] = helper_lmebestfit(data.between, 'rt ~ -1 + i + list:pool', ...
                                                {'(-1+i|ppn)'; ...
                                                 '(loc|ppn)'; ...
                                                 '(1|ppn:spkr)'; ...
                                                 '(1|ppn:id)'; ...
                                                 '(1|spkr:id)'; ...
                                                 '(rep|ppn)'; ...
                                                 '(-1+list:pool|ppn)'});
%%
coefTest(models3{best3}.lme, [0 0 0 0 0 1 -1 0 0 0])
coefTest(models3{best3}.lme, [0 1 0 -1 0 0 0 0 0 0])

                                             
                                             
%%
coefTest(models{best}.lme, [0 0 1 0 -1 0 0 0 0 0 0])
coefTest(models{best}.lme, [0 0 0 0 0 0 1 -1 0 0 0])
coefTest(models{best}.lme, [0 0 1 0 0 0 0 0 0 0 -1])
coefTest(models{best}.lme, [0 0 0 0 0 0 1 0 0 0 -1])

%%
t = fitlme(data.between, 'rtl ~ -1 + i + list:pool + (-1+i|ppn) + (loc|ppn) + (1|ppn:id) + (1|ppn:spkr) + (1|spkr:id) + (-1+list:pool|ppn)', 'FitMethod', 'REML', 'DummyVarCoding', 'full')
coefTest(t, [0 1 0 -1 0 0 0 0 0 0])
coefTest(t, [0 0 0 0 0 1 -1 0 0 0])
coefTest(t, [0 1 0 0 0 0 0 0 0 -1])
coefTest(t, [0 0 0 0 0 1 0 0 0 -1])


%%
[B, n, s] = randomEffects(models{8}.lme);

%%
ppns = unique(data.between.ppn);
figure;

subplot(2, 1, 1);

for i = 1:size(ppns, 1)
    l1p1 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_1:list_1'));
    l1p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_3:list_1'));
    l3p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_3:list_3'));
       
    plot([1 2 3], [l1p1 l1p3 l3p3], 'o-'); hold on
end

subplot(2, 1, 2);

for i = 1:size(ppns, 1)
    l2p2 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_2:list_2'));
    l2p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_3:list_2'));
    l3p3 = B(strcmp(string(n.Level), string(ppns(i))) & ...
             strcmp(string(n.Name), 'pool_3:list_3'));
         
    plot([1 2 3], [l2p2 l2p3 l3p3], 'o-'); hold on
end