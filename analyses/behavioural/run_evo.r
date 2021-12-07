### 0: preamble
# pracma:
# required for erfcinv for MAD outlier analysis to calculate
# the scaling constant -1 / (sqrt(2) * erfcinv(3/2)) precisely
library(pracma);

# lme4
# required for model building
library(lme4);

# lmerTest
# required for obtaining p-values for model coefficients
library(lmerTest);

# MASS
# required for building successive difference contrasts 
# in our modelling approach (and for ginv for other 
# contrasts we specify)
library(MASS);

# multcomp
# required for running the post-hoc contrast on the 
# coefficients of the fitted model
library(multcomp);

# emmeans
# required for extracting marginal means from
# the fitted model for visualisation purposes
library(emmeans);

# ggplot2
# required for plotting
library(ggplot2);

# viridis
# required for plotting in nice colour blind-accessible
# colour palette
library(viridis);

# latex2exp
# required for using LaTeX in ggplot
library(latex2exp);

# ggsignif
# required for easy plotting of significance indicators
# in our figures
library(ggsignif);

# svglite
# required for exporting figures as scalable vector graphics
library(svglite);

# R.matlab
# for exporting data to matlab-readable matrices
library(R.matlab);

setwd("/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/")
file_2afcd <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_2AFCD_False.txt"; # collection to load
file_2afcw <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_2AFCW_False.txt"; # collection to load
file_meg <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_MEG_False.txt"; # collection to load
file_4afc <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_4AFC_False.txt"; # collection to load
outdir <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/out/";


system("module unload python && module load python/3.4.2 && cd /project/3018012.23/git/analyses/behavioural/ && python prep_aggregate.py --none --2AFCW && python prep_aggregate.py --none --2AFCD && python prep_aggregate.py --none --4AFC"); # collect data on /project/


### 1: load, recode and preprocess data
## 1.1: handle 2AFCD data
data <- read.delim(file_2afcd, header = TRUE, sep = "\t", dec=".");


data$task <- '2AFCD';
data$ppn <- factor(data$ppn);                         # factor: participant id
spkr <- data$id;                                      # fix column mix up
data$id <- factor(data$spkr);                         # factor: item id
data$spkr <- factor(spkr);                            # factor: speaker id
data$var <- factor(data$var);                         # factor: speaker:item variant
data$pool <- factor(data$pool);                       # factor: speaker pool
data$list <- factor(data$list);                       # factor: item list
data$cor <- as.numeric(as.character(data$cor));       # continuous: correct response (1 = TRUE, 0 = FALSE)
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id)) + 0);
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data$condition <- factor(data$condition);


# subset
d_2afcd <- subset(data, select = c(task, ppn, id, spkr, var, pool, list, cor, rt, i, rep, condition));


# outliers
data.controlled <- subset(d_2afcd, cor == 1);
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, mad, constant=(-1/(sqrt(2)*erfcinv(3/2)))), c('ppn', 'condition', 'mad_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, median), c('ppn', 'condition', 'median_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- subset(data.controlled, rt >= median_by_ppncond - (3 * mad_by_ppncond) & rt <= median_by_ppncond + (3 * mad_by_ppncond));
d_2afcd.mad <- data.controlled;


## 1.2: handle 2AFCW data
data <- read.delim(file_2afcw, header = TRUE, sep = "\t", dec=".");


data$task <- '2AFCW'
data$ppn <- factor(data$ppn);                         # factor: participant id
spkr <- data$id;                                      # fix the column mix up
data$id <- factor(data$spkr);                         # factor: item id
data$spkr <- factor(spkr);                            # factor: speaker id
data$var <- factor(data$var);                         # factor: speaker:item variant
data$pool <- factor(data$pool);                       # factor: speaker pool
data$list <- factor(data$list);                       # factor: item list
data$cor <- as.numeric(as.character(data$cor));       # continuous: correct response (1 = TRUE, 0 = FALSE)
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id)) + 4);
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data$condition <- factor(data$condition);


# subset
d_2afcw <- subset(data, select = c(task, ppn, id, spkr, var, pool, list, cor, rt, i, rep, condition));


# outliers
data.controlled <- subset(d_2afcw, cor == 1);
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, mad, constant=(-1/(sqrt(2)*erfcinv(3/2)))), c('ppn', 'condition', 'mad_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, median), c('ppn', 'condition', 'median_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- subset(data.controlled, rt >= median_by_ppncond - (3 * mad_by_ppncond) & rt <= median_by_ppncond + (3 * mad_by_ppncond));
d_2afcw.mad <- data.controlled;


## 1.3: handle MEG data
data <- read.delim(file_meg, header = TRUE, sep = "\t", dec=".");

data$task <- 'MEG';
data$ppn <- factor(data$ppn);
data$id <- factor(data$id);
data$spkr <- factor(data$spkr);
data$var <- factor(data$var);
data$pool <- factor(data$pool);
data$list <- factor(data$list);
data$cor <- factor(as.numeric(data$r != -1));
data$rt <- as.numeric(as.character(data$rt));
data$i <- as.numeric(as.character(data$i));
data$unique <- seq_along(data$ppn);


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id)) + 8);
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 1 & data$pool == 3,]$condition <- 'L1P3';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data[data$list == 2 & data$pool == 3,]$condition <- 'L2P3';


# subset
d_meg <- subset(data, select = c(task, ppn, id, spkr, var, pool, list, cor, rt, i, rep, condition));


# outliers
data.controlled <- subset(d_meg, cor == 1);
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, mad, constant=(-1/(sqrt(2)*erfcinv(3/2)))), c('ppn', 'condition', 'mad_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, median), c('ppn', 'condition', 'median_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- subset(data.controlled, rt >= median_by_ppncond - (3 * mad_by_ppncond) & rt <= median_by_ppncond + (3 * mad_by_ppncond));
d_meg.mad <- data.controlled;


## 1.4: handle 4AFC data
data <- read.delim(file_4afc, header = TRUE, sep = "\t", dec=".");


data$task <- '4AFC';
data$ppn <- factor(data$ppn);                         # factor: participant id
id <- factor(data$id);                                # fix the miscoding of spkr/id
data$id <- factor(data$spkr);                         # factor: item id
data$spkr <- factor(id);                              # factor: speaker id
data$var <- factor(data$var);                         # factor: speaker:item variant
data$pool <- factor(data$pool);                       # factor: speaker pool
data$list <- factor(data$list);                       # factor: item list
data$cor <- as.numeric(as.character(data$c));         # continuous: correct response (1 = TRUE, 0 = FALSE)
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id)) + 12);
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 1 & data$pool == 2,]$condition <- 'L1P2';
data[data$list == 1 & data$pool == 3,]$condition <- 'L1P3';
data[data$list == 2 & data$pool == 1,]$condition <- 'L2P1';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data[data$list == 2 & data$pool == 3,]$condition <- 'L2P3';
data[data$list == 3 & data$pool == 1,]$condition <- 'L3P1';
data[data$list == 3 & data$pool == 2,]$condition <- 'L3P2';
data[data$list == 3 & data$pool == 3,]$condition <- 'L3P3';
data$condition <- factor(data$condition);


# subset
d_4afc <- subset(data, select = c(task, ppn, id, spkr, var, pool, list, cor, rt, i, rep, condition));


# outliers
data.controlled <- subset(d_4afc, cor == 1);
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, mad, constant=(-1/(sqrt(2)*erfcinv(3/2)))), c('ppn', 'condition', 'mad_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, median), c('ppn', 'condition', 'median_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- subset(data.controlled, rt >= median_by_ppncond - (3 * mad_by_ppncond) & rt <= median_by_ppncond + (3 * mad_by_ppncond));
d_4afc.mad <- data.controlled;


## 1.5: collect, bind and recode all data
rm(data);
data <- rbind(d_2afcd.mad, d_2afcw.mad, d_meg.mad, d_4afc.mad);
data$task <- factor(data$task);
data$unique <- seq_along(data$ppn);


# recode speaker repetitions
data$reps <- 0;

for(it in data$unique) {
  data[data$unique == it,]$reps = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & spkr == data[data$unique == it,]$spkr)));
}


# factorise
data$RepM <- factor(data$rep);
data$RepS <- factor(data$reps);


### 2: model effects and plot results
## 2.1: extract learning effects
# The rationale here is the, essentially, we want to fit LMMs 
# per participant to extract ß-values of interest (similar to
# how we would analyse fMRI data). In this case, we do so for
# data from only L1P1 & L2P2 across all tasks. For all model
# contrasts, we use the identity matrix of our variables. We
# then extract the slopes (repetition crossed by variable),
# z-transform them (within participant), evaluate their dis-
# tribution and finally calculate their spearman correlation.
# We plot data to show: a GLM slope + CI, distance from the
# predictions for each data point, rho and significance.

df <- data.frame(ppn = character(0),
                 word = character(0),
                 speaker = character(0),
                 list = integer(0),
                 pool = integer(0),
                 wordeff = double(0),
                 spkreff = double(0), stringsAsFactors = FALSE);

for (this_ppn in unique(data$ppn)) {
  byppn.data <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2'));
  byppn.data$spkr <- factor(byppn.data$spkr, levels=unique(byppn.data$spkr));
  contrasts(byppn.data$spkr) <- diag(NROW(unique(byppn.data$spkr)));
  byppn.data$id <- factor(byppn.data$id, levels=unique(byppn.data$id));
  contrasts(byppn.data$id) <- diag(NROW(unique(byppn.data$id)));
  byppn.lme <- lmer(rt ~ rep:id + reps:spkr + (1|task), data = byppn.data);
  byppn.fixef <- fixef(byppn.lme);
  
  byppn.ref <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2') & (task == '2AFCD' | task == '2AFCW'));
  
  for (id in unique(byppn.ref$id)) {
    speakers_this_word <- unique(byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$spkr);
    
    for (sptw in speakers_this_word) {
      df[NROW(df)+1,] <- c(this_ppn, 
                           id, 
                           sptw, 
                           byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$list[1],
                           byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$pool[1],
                           byppn.fixef[sprintf("rep:id%s", id)][1],
                           byppn.fixef[sprintf("reps:spkr%s", sptw)][1]);
    }
  }
}


df_focused <- subset(df, (list == 1 & pool == 1) | (list == 2 & pool == 2));
df_avail <- df_focused[complete.cases(df_focused),];
df_avail$wordeff <- as.numeric(df_avail$wordeff);
df_avail$spkreff <- as.numeric(df_avail$spkreff);


## 2.2: z-score (within-pp), write to matlab, plot
df_avail$zword <- 0;
df_avail$zspkr <- 0;

# partition data
df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);

for (ppn in unique(df_avail$ppn)) {
  df_avail[df_avail$ppn == ppn,]$zword = (df_avail[df_avail$ppn == ppn,]$wordeff - mean(df_avail[df_avail$ppn == ppn,]$wordeff)) / sd(df_avail[df_avail$ppn == ppn,]$wordeff);
  df_avail[df_avail$ppn == ppn,]$zspkr = (df_avail[df_avail$ppn == ppn,]$spkreff - mean(df_avail[df_avail$ppn == ppn,]$spkreff)) / sd(df_avail[df_avail$ppn == ppn,]$spkreff);
  
  df_avail_l1[df_avail_l1$ppn == ppn,]$zword = (df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff - mean(df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff)) / sd(df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff);
  df_avail_l1[df_avail_l1$ppn == ppn,]$zspkr = (df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff - mean(df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff)) / sd(df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff);
  
  df_avail_l2[df_avail_l2$ppn == ppn,]$zword = (df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff - mean(df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff)) / sd(df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff);
  df_avail_l2[df_avail_l2$ppn == ppn,]$zspkr = (df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff - mean(df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff)) / sd(df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff);
}

df_avail_l1_iso <- df_avail_l1;
df_avail_l2_iso <- df_avail_l2;

df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);


# check distribution
hist(df_avail$zword)
hist(df_avail$zspkr)

hist(df_avail_l1$zword)
hist(df_avail_l2$zword)
hist(df_avail_l1$zspkr)
hist(df_avail_l2$zspkr)


# all data
overall_corr <- cor.test(df_avail$zspkr, df_avail$zword, method = 'spearman', exact = FALSE);

corr.x <- seq(from = min(df_avail$zspkr), to = max(df_avail$zspkr), by = 0.01);
corr.y <- corr.x * overall_corr[["estimate"]][1];

corr <- data.frame(zspkr = corr.x, fit = corr.y)
corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', overall_corr[["estimate"]][1])));
corr.p <- overall_corr[["p.value"]][1]
if (corr.p <= 1e-3) { corr.p <- '***'; } else if (corr.p <= 1e-2) { corr.p <- '**'; } else if (corr.p <= 5e-2) { corr.p <- '*'; } else { corr.p <- 'n.s.'; }
corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(corr.p))

corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

mod <- lm(zword ~ zspkr, df_avail);
mod.p <- predict.lm(mod, data.frame(zspkr = corr$zspkr), interval = "confidence");
mod.v <- data.frame(x = corr$zspkr, y = mod.p[,1], ci_lb = mod.p[,2], ci_ub = mod.p[,3]);

df_avail$dist <- apply(df_avail, MARGIN=1, FUN=corr.dist, A = c(mod.v[1,]$x, mod.v[1,]$y), B = c(mod.v[NROW(mod.v),]$x, mod.v[NROW(mod.v),]$y));


mt <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = corr.s, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker learning (z-score)"), y = "Word learning (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_l.svg"), width=4, height=4, plot=mt)
ggsave(file=file.path(outdir, "run_evo_l.png"), width=4, height=4, plot=mt)


# low variability
l1_corr <- cor.test(df_avail_l1$zspkr, df_avail_l1$zword, method = 'spearman', exact = FALSE);

l1corr.x <- seq(from = min(df_avail_l1$zspkr), to = max(df_avail_l1$zspkr), by = 0.01);
l1corr.y <- l1corr.x * l1_corr[["estimate"]][1];

l1corr <- data.frame(zspkr = l1corr.x, fit = l1corr.y)
l1corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l1_corr[["estimate"]][1])));
l1corr.p <- l1_corr[["p.value"]][1]
if (l1corr.p <= 1e-3) { l1corr.p <- '***'; } else if (l1corr.p <= 1e-2) { l1corr.p <- '**'; } else if (l1corr.p <= 5e-2) { l1corr.p <- '*'; } else { l1corr.p <- 'n.s.'; }
l1corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(l1corr.p))

l1corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

l1mod <- lm(zword ~ zspkr, df_avail_l1);
l1mod.p <- predict.lm(l1mod, data.frame(zspkr = l1corr$zspkr), interval = "confidence");
l1mod.v <- data.frame(x = l1corr$zspkr, y = l1mod.p[,1], ci_lb = l1mod.p[,2], ci_ub = l1mod.p[,3]);

df_avail_l1$dist <- apply(df_avail_l1, MARGIN=1, FUN=l1corr.dist, A = c(l1mod.v[1,]$x, l1mod.v[1,]$y), B = c(l1mod.v[NROW(l1mod.v),]$x, l1mod.v[NROW(l1mod.v),]$y));

mt_l1 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l1, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l1mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = l1mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = l1corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = l1corr.s, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker learning (z-score)"), y = "Word learning (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_lv_l.svg"), width=4, height=4, plot=mt_l1)
ggsave(file=file.path(outdir, "run_evo_lv_l.png"), width=4, height=4, plot=mt_l1)


# high variability
l2_corr <- cor.test(df_avail_l2$zspkr, df_avail_l2$zword, method = 'spearman', exact = FALSE);

l2corr.x <- seq(from = min(df_avail_l2$zspkr), to = max(df_avail_l2$zspkr), by = 0.01);
l2corr.y <- l2corr.x * l2_corr[["estimate"]][1];

l2corr <- data.frame(zspkr = l2corr.x, fit = l2corr.y)
l2corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l2_corr[["estimate"]][1])));
l2corr.p <- l2_corr[["p.value"]][1]
if (l2corr.p <= 1e-3) { l2corr.p <- '***'; } else if (l2corr.p <= 1e-2) { l2corr.p <- '**'; } else if (l2corr.p <= 5e-2) { l2corr.p <- '*'; } else { l2corr.p <- 'n.s.'; }
l2corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(l2corr.p))

l2corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

l2mod <- lm(zword ~ zspkr, df_avail_l2);
l2mod.p <- predict.lm(l2mod, data.frame(zspkr = l2corr$zspkr), interval = "confidence");
l2mod.v <- data.frame(x = l2corr$zspkr, y = l2mod.p[,1], ci_lb = l2mod.p[,2], ci_ub = l2mod.p[,3]);

df_avail_l2$dist <- apply(df_avail_l2, MARGIN=1, FUN=l2corr.dist, A = c(l2mod.v[1,]$x, l2mod.v[1,]$y), B = c(l2mod.v[NROW(l2mod.v),]$x, l2mod.v[NROW(l2mod.v),]$y));

mt_l2 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l2, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l2mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = l2mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = l2corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = l2corr.s, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker learning (z-score)"), y = "Word learning (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_hv_l.svg"), width=4, height=4, plot=mt_l2)
ggsave(file=file.path(outdir, "run_evo_hv_l.png"), width=4, height=4, plot=mt_l2)


# export to matlab
writeMat(file.path(outdir, "learning_scores.mat"), x = as.matrix(df_avail));


## 2.3: extract word- and speaker-specific recognition effects
# The rationale here is the, essentially, we want to fit LMMs 
# per participant to extract ß-values of interest (similar to
# how we would analyse fMRI data). In this case, we do so for
# data from only L1P1, L2P2, L1P3, L2P3, L3P3 across all tasks. 
# For all model contrasts, we use the identity matrix of our
# variables, but then set the respective controls (i.e., list3
# or pool3) as the intercept of the model. Finally, we then 
# extract the ß-estimates (in this case, from our factors),
# z-transform them (within participant), evaluate their dis-
# tribution and finally calculate their spearman correlation.
# We plot data to show: a GLM slope + CI, distance from the
# predictions for each data point, rho and significance.

df <- data.frame(ppn = character(0),
                 word = character(0),
                 speaker = character(0),
                 list = integer(0),
                 pool = integer(0),
                 wordeff = double(0),
                 spkreff = double(0), stringsAsFactors = FALSE);

for (this_ppn in unique(data$ppn)) {
  byppn.data <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2' | condition == 'L1P3' | condition == 'L2P3' | condition == 'L3P1' | condition == 'L3P2' | condition == 'L3P3'));
  
  byppn.control <- byppn.data[byppn.data$condition == 'L3P3',];
  byppn.control.id <- unique(byppn.control$id);
  byppn.control.spkr <- unique(byppn.control$spkr);
  
  byppn.data$spkr <- factor(byppn.data$spkr, levels=unique(byppn.data$spkr));
  byppn.control.spkrc <- diag(NROW(unique(byppn.data$spkr)));
  rownames(byppn.control.spkrc) <- unique(byppn.data$spkr);
  colnames(byppn.control.spkrc) <- unique(byppn.data$spkr);
  byppn.control.spkrc[rownames(byppn.control.spkrc) %in% byppn.control.spkr,] <- 0;
  contrasts(byppn.data$spkr) <- byppn.control.spkrc;
  
  byppn.data$id <- factor(byppn.data$id, levels=unique(byppn.data$id));
  byppn.control.idc <- diag(NROW(unique(byppn.data$id)))
  rownames(byppn.control.idc) <- unique(byppn.data$id);
  colnames(byppn.control.idc) <- unique(byppn.data$id);
  byppn.control.idc[rownames(byppn.control.idc) %in% byppn.control.id,] <- 0;
  contrasts(byppn.data$id) <- byppn.control.idc;
  
  byppn.lme <- lmer(rt ~ rep + id + reps + spkr + (1|task), data = byppn.data);
  byppn.fixef <- fixef(byppn.lme);
  
  byppn.ref <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2') & task == '2AFCD');
  
  for (id in unique(byppn.ref$id)) {
    speakers_this_word <- unique(byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$spkr);
    
    for (sptw in speakers_this_word) {
      df[NROW(df)+1,] <- c(this_ppn, 
                           id, 
                           sptw, 
                           byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$list[1],
                           byppn.ref[byppn.ref$ppn == this_ppn & byppn.ref$id == id,]$pool[1],
                           byppn.fixef[sprintf("id%s", id)][1],
                           byppn.fixef[sprintf("spkr%s", sptw)][1]);
    }
  }
}

df_focused <- subset(df, (list == 1 & pool == 1) | (list == 2 & pool == 2));
df_avail <- df_focused[complete.cases(df_focused),];
df_avail$wordeff <- as.numeric(df_avail$wordeff);
df_avail$spkreff <- as.numeric(df_avail$spkreff);


## 2.4: z-score (within-pp), write to matlab, plot
df_avail$zword <- 0;
df_avail$zspkr <- 0;


# partition data
df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);

for (ppn in unique(df_avail$ppn)) {
  df_avail[df_avail$ppn == ppn,]$zword = (df_avail[df_avail$ppn == ppn,]$wordeff - mean(df_avail[df_avail$ppn == ppn,]$wordeff)) / sd(df_avail[df_avail$ppn == ppn,]$wordeff);
  df_avail[df_avail$ppn == ppn,]$zspkr = (df_avail[df_avail$ppn == ppn,]$spkreff - mean(df_avail[df_avail$ppn == ppn,]$spkreff)) / sd(df_avail[df_avail$ppn == ppn,]$spkreff);
  
  df_avail_l1[df_avail_l1$ppn == ppn,]$zword = (df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff - mean(df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff)) / sd(df_avail_l1[df_avail_l1$ppn == ppn,]$wordeff);
  df_avail_l1[df_avail_l1$ppn == ppn,]$zspkr = (df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff - mean(df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff)) / sd(df_avail_l1[df_avail_l1$ppn == ppn,]$spkreff);
  
  df_avail_l2[df_avail_l2$ppn == ppn,]$zword = (df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff - mean(df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff)) / sd(df_avail_l2[df_avail_l2$ppn == ppn,]$wordeff);
  df_avail_l2[df_avail_l2$ppn == ppn,]$zspkr = (df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff - mean(df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff)) / sd(df_avail_l2[df_avail_l2$ppn == ppn,]$spkreff);
}

df_avail_l1_iso <- df_avail_l1;
df_avail_l2_iso <- df_avail_l2;

df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);


# check distribution
hist(df_avail$zword)
hist(df_avail$zspkr)

hist(df_avail_l1$zword)
hist(df_avail_l2$zword)
hist(df_avail_l1$zspkr)
hist(df_avail_l2$zspkr)


# all data
overall_corr <- cor.test(df_avail$zspkr, df_avail$zword, method = 'spearman', exact = FALSE);

corr.x <- seq(from = min(df_avail$zspkr), to = max(df_avail$zspkr), by = 0.01);
corr.y <- corr.x * overall_corr[["estimate"]][1];

corr <- data.frame(zspkr = corr.x, fit = corr.y)
corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', overall_corr[["estimate"]][1])));
corr.p <- overall_corr[["p.value"]][1]
if (corr.p <= 1e-3) { corr.p <- '***'; } else if (corr.p <= 1e-2) { corr.p <- '**'; } else if (corr.p <= 5e-2) { corr.p <- '*'; } else { corr.p <- 'n.s.'; }
corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(corr.p))


corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

mod <- lm(zword ~ zspkr, df_avail);
mod.p <- predict.lm(mod, data.frame(zspkr = corr$zspkr), interval = "confidence");
mod.v <- data.frame(x = corr$zspkr, y = mod.p[,1], ci_lb = mod.p[,2], ci_ub = mod.p[,3]);

df_avail$dist <- apply(df_avail, MARGIN=1, FUN=corr.dist, A = c(mod.v[1,]$x, mod.v[1,]$y), B = c(mod.v[NROW(mod.v),]$x, mod.v[NROW(mod.v),]$y));

mt <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = corr.s, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_ws.svg"), width=4, height=4, plot=mt)
ggsave(file=file.path(outdir, "run_evo_ws.png"), width=4, height=4, plot=mt)


# low-variability
l1_corr <- cor.test(df_avail_l1$zspkr, df_avail_l1$zword, method = 'spearman', exact = FALSE);

l1corr.x <- seq(from = min(df_avail_l1$zspkr), to = max(df_avail_l1$zspkr), by = 0.01);
l1corr.y <- l1corr.x * l1_corr[["estimate"]][1];

l1corr <- data.frame(zspkr = l1corr.x, fit = l1corr.y)
l1corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l1_corr[["estimate"]][1])));
l1corr.p <- l1_corr[["p.value"]][1]
if (l1corr.p <= 1e-3) { l1corr.p <- '***'; } else if (l1corr.p <= 1e-2) { l1corr.p <- '**'; } else if (l1corr.p <= 5e-2) { l1corr.p <- '*'; } else { l1corr.p <- 'n.s.'; }
l1corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(l1corr.p))

l1corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

l1mod <- lm(zword ~ zspkr, df_avail_l1);
l1mod.p <- predict.lm(l1mod, data.frame(zspkr = l1corr$zspkr), interval = "confidence");
l1mod.v <- data.frame(x = l1corr$zspkr, y = l1mod.p[,1], ci_lb = l1mod.p[,2], ci_ub = l1mod.p[,3]);

df_avail_l1$dist <- apply(df_avail_l1, MARGIN=1, FUN=l1corr.dist, A = c(l1mod.v[1,]$x, l1mod.v[1,]$y), B = c(l1mod.v[NROW(l1mod.v),]$x, l1mod.v[NROW(l1mod.v),]$y));

mt_l1 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l1, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l1mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = l1mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = l1corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = l1corr.s, aes(x = x, y = y, label = label)) +
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_lv_ws.svg"), width=4, height=4, plot=mt_l1)
ggsave(file=file.path(outdir, "run_evo_lv_ws.png"), width=4, height=4, plot=mt_l1)


# high-variability
l2_corr <- cor.test(df_avail_l2$zspkr, df_avail_l2$zword, method = 'spearman', exact = FALSE);

l2corr.x <- seq(from = min(df_avail_l2$zspkr), to = max(df_avail_l2$zspkr), by = 0.01);
l2corr.y <- l2corr.x * l2_corr[["estimate"]][1];

l2corr <- data.frame(zspkr = l2corr.x, fit = l2corr.y)
l2corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l2_corr[["estimate"]][1])));
l2corr.p <- l2_corr[["p.value"]][1]
if (l2corr.p <= 1e-3) { l2corr.p <- '***'; } else if (l2corr.p <= 1e-2) { l2corr.p <- '**'; } else if (l2corr.p <= 5e-2) { l2corr.p <- '*'; } else { l2corr.p <- 'n.s.'; }
l2corr.s <- data.frame(x = c(2.5), y = c(3.9), label = c(l2corr.p))

l2corr.dist <- function(r, A, B) {
  p <- c(as.numeric(r[[9]]), as.numeric(r[[8]]));
  v1 <- A - B;
  v2 <- p - A;
  m <- cbind(v1, v2);
  d <- abs(det(m)) / sqrt(sum(v1**2))
}

l2mod <- lm(zword ~ zspkr, df_avail_l2);
l2mod.p <- predict.lm(l2mod, data.frame(zspkr = l2corr$zspkr), interval = "confidence");
l2mod.v <- data.frame(x = l2corr$zspkr, y = l2mod.p[,1], ci_lb = l2mod.p[,2], ci_ub = l2mod.p[,3]);

df_avail_l2$dist <- apply(df_avail_l2, MARGIN=1, FUN=l2corr.dist, A = c(l2mod.v[1,]$x, l2mod.v[1,]$y), B = c(l2mod.v[NROW(l2mod.v),]$x, l2mod.v[NROW(l2mod.v),]$y));

mt_l2 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l2, aes(x = zspkr, y = zword, colour = dist), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l2mod.v, aes(x = x, y = y)) + 
  geom_ribbon(data = l2mod.v, aes(x = x, ymin = ci_lb, ymax = ci_ub), alpha = 0.15) + 
  
  # annotate
  geom_text(data = l2corr.a, aes(x = x, y = y, label = label)) + 
  geom_text(data = l2corr.s, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_hv_ws.svg"), width=4, height=4, plot=mt_l2)
ggsave(file=file.path(outdir, "run_evo_hv_ws.png"), width=4, height=4, plot=mt_l2)


# export to matlab
writeMat(file.path(outdir, "ws_scores.mat"), x = as.matrix(df_avail));
