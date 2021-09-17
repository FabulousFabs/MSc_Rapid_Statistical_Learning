### 0: preamble
setwd("/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/")
file_2afcd <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_2AFCD_False.txt"; # collection to load
file_2afcw <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_2AFCW_False.txt"; # collection to load
file_meg <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_MEG_False.txt"; # collection to load
file_4afc <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_4AFC_False.txt"; # collection to load
outdir <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/out/";


system("module unload python && module load python/3.4.2 && cd /project/3018012.23/git/analyses/behavioural/ && python prep_aggregate.py --none --2AFCW && python prep_aggregate.py --none --2AFCD && python prep_aggregate.py --none --4AFC"); # collect data on /project/


### 1: load, recode and preprocess data
# handle 2AFCD data
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


# handle 2AFCW data
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


# handle MEG data
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


# handle 4AFC data
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


# collect data
rm(data);
data <- rbind(d_2afcd.mad, d_2afcw.mad, d_meg.mad, d_4afc.mad);
data$task <- factor(data$task);
data$unique <- seq_along(data$ppn);


# recode speaker repetitions
data$reps <- 0;

for(it in data$unique) {
  data[data$unique == it,]$reps = (NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & spkr == data[data$unique == it,]$spkr)));
}


data$RepM <- factor(data$rep);
data$RepS <- factor(data$reps);


##
df <- data.frame(ppn = character(0),
                 word = character(0),
                 speaker = character(0),
                 list = integer(0),
                 pool = integer(0),
                 wordeff = double(0),
                 spkreff = double(0), stringsAsFactors = FALSE);

for (this_ppn in unique(data$ppn)) {
  byppn.data <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2' | condition == 'L1P3' | condition == 'L2P3' | condition == 'L3P1' | condition == 'L3P2'));
  #byppn.data <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2'));
  byppn.data$spkr <- factor(byppn.data$spkr, levels=unique(byppn.data$spkr));
  byppn.data$id <- factor(byppn.data$id, levels=unique(byppn.data$id));
  #byppn.lme <- lmer(rt ~ rep + id + reps + spkr + (1|task), data = byppn.data);
  #byppn.lme <- lmer(rt ~ rep + id + reps + spkr + (1|condition), data = byppn.data);
  byppn.lme <- lmer(rt ~ rep + id + reps + spkr + (1|task), data = byppn.data);
  #byppn.lme <- lm(rt ~ condition + rep + id + reps + spkr, data = byppn.data);
  byppn.fixef <- fixef(byppn.lme);
  
  byppn.ref <- subset(data, ppn == this_ppn & (condition == 'L1P1' | condition == 'L2P2') & task == '2AFCD' & rep == 1);
  
  for (id in unique(byppn.ref$id)) {
    speakers_this_word <- unique(byppn.data[byppn.data$ppn == this_ppn & byppn.data$id == id,]$spkr);
    
    for (sptw in speakers_this_word) {
      df[NROW(df)+1,] <- c(this_ppn, 
                           id, 
                           sptw, 
                           byppn.data[byppn.data$ppn == this_ppn & byppn.data$id == id,]$list[1],
                           byppn.data[byppn.data$ppn == this_ppn & byppn.data$id == id,]$pool[1],
                           byppn.fixef[sprintf("id%s", id)][1],
                           byppn.fixef[sprintf("spkr%s", sptw)][1]);
    }
  }
}

df_focused <- subset(df, (list == 1 & pool == 1) | (list == 2 & pool == 2));
df_avail <- df_focused[complete.cases(df_focused),];
df_avail$wordeff <- as.numeric(df_avail$wordeff);
df_avail$spkreff <- as.numeric(df_avail$spkreff);

cor.test(df_avail$spkreff, df_avail$wordeff);
ggplot(df_avail, aes(x = spkreff, y = wordeff, colour = ppn)) + geom_point()

df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);

cor.test(df_avail_l1$spkreff, df_avail_l1$wordeff);
ggplot(df_avail_l1, aes(x = spkreff, y = wordeff, colour = ppn)) + geom_point()

cor.test(df_avail_l2$spkreff, df_avail_l2$wordeff);
ggplot(df_avail_l2, aes(x = spkreff, y = wordeff, colour = ppn)) + geom_point()

df_avail$zword <- 0;
df_avail$zspkr <- 0;

for (ppn in unique(df_avail$ppn)) {
  df_avail[df_avail$ppn == ppn,]$zword = (df_avail[df_avail$ppn == ppn,]$wordeff - mean(df_avail[df_avail$ppn == ppn,]$wordeff)) / sd(df_avail[df_avail$ppn == ppn,]$wordeff);
  df_avail[df_avail$ppn == ppn,]$zspkr = (df_avail[df_avail$ppn == ppn,]$spkreff - mean(df_avail[df_avail$ppn == ppn,]$spkreff)) / sd(df_avail[df_avail$ppn == ppn,]$spkreff);
}

overall_corr <- cor.test(df_avail$zspkr, df_avail$zword);

corr.x <- seq(from = min(df_avail$zspkr), to = max(df_avail$zspkr), by = 0.01);
corr.y <- corr.x * overall_corr[["estimate"]][1];

corr <- data.frame(zspkr = corr.x, fit = corr.y)
corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', overall_corr[["estimate"]][1])));

mt <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail, aes(x = zspkr, y = zword, colour = ppn), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = corr, aes(x = zspkr, y = fit)) + 
  
  # annotate
  geom_text(data = corr.a, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_overall.svg"), width=4, height=4, plot=mt)
ggsave(file=file.path(outdir, "run_evo_overall.png"), width=4, height=4, plot=mt)


df_avail_l1 <- subset(df_avail, list == 1 & pool == 1);
df_avail_l2 <- subset(df_avail, list == 2 & pool == 2);

l1_corr <- cor.test(df_avail_l1$zspkr, df_avail_l1$zword);

l1corr.x <- seq(from = min(df_avail_l1$zspkr), to = max(df_avail_l1$zspkr), by = 0.01);
l1corr.y <- l1corr.x * l1_corr[["estimate"]][1];

l1corr <- data.frame(zspkr = l1corr.x, fit = l1corr.y)
l1corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l1_corr[["estimate"]][1])));

mt_l1 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l1, aes(x = zspkr, y = zword, colour = ppn), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l1corr, aes(x = zspkr, y = fit)) + 
  
  # annotate
  geom_text(data = l1corr.a, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_l1.svg"), width=4, height=4, plot=mt_l1)
ggsave(file=file.path(outdir, "run_evo_l1.png"), width=4, height=4, plot=mt_l1)


l2_corr <- cor.test(df_avail_l2$zspkr, df_avail_l2$zword);

l2corr.x <- seq(from = min(df_avail_l2$zspkr), to = max(df_avail_l2$zspkr), by = 0.01);
l2corr.y <- l2corr.x * l2_corr[["estimate"]][1];

l2corr <- data.frame(zspkr = l2corr.x, fit = l2corr.y)
l2corr.a <- data.frame(x = c(2.5), y = c(3.5), label = c(sprintf('\U000003C1 = %.2f', l2_corr[["estimate"]][1])));

mt_l2 <- 
  ggplot() + 
  
  # add scatter
  geom_point(data = df_avail_l2, aes(x = zspkr, y = zword, colour = ppn), show.legend = FALSE) + 
  
  # add trend
  geom_line(data = l2corr, aes(x = zspkr, y = fit)) + 
  
  # annotate
  geom_text(data = l2corr.a, aes(x = x, y = y, label = label)) + 
  
  # add labels
  labs(x = TeX("Speaker effect (z-score)"), y = "Word effect (z-score)") + 
  ylim(-4, 4) + 
  xlim(-4, 4) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.1, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_evo_l2.svg"), width=4, height=4, plot=mt_l2)
ggsave(file=file.path(outdir, "run_evo_l2.png"), width=4, height=4, plot=mt_l2)
