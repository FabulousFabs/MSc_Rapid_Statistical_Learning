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


setwd("/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/")
file <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_2AFCD_False.txt"; # collection to load
outdir <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/out/";


system("module unload python && module load python/3.4.2 && cd /project/3018012.23/git/analyses/behavioural/ && python prep_aggregate.py --none --2AFCD"); # collect data on /project/



### 1: load, recode and preprocess data
data <- read.delim(file, header = TRUE, sep = "\t", dec=".");


data$ppn <- factor(data$ppn);                         # factor: participant id
id <- factor(data$id);                                # fix the miscoding of spkr/id
data$id <- factor(data$spkr);                         # factor: item id
data$spkr <- factor(id);                              # factor: speaker id
data$var <- factor(data$var);                         # factor: speaker:item variant
data$dur <- as.numeric(as.character(data$dur));       # continuous: duration
data$f <- as.character(data$f);                       # string: file
data$pool <- factor(data$pool);                       # factor: speaker pool
data$list <- factor(data$list);                       # factor: item list
data$def <- factor(data$def);                         # factor: definition id
id <- factor(data$f_spkr);                            # fix the miscoding of spkr/id
data$f_spkr <- factor(data$f_id);                     # factor: foil speaker
data$f_id <- factor(id);                              # factor: foil id
data$f_var <- factor(data$f_var);                     # factor: foil var
data$f_dur <- factor(data$f_dur);                     # factor: foil duration
data$c <- as.numeric(as.character(data$c));           # continuous: correct response (1 = TRUE, 0 = FALSE)
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$rtl <- log10(as.numeric(as.character(data$rt))); # continuous: reaction time (log10)
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id & list == data[data$unique == it,]$list & pool == data[data$unique == it,]$pool));
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data$condition <- factor(data$condition);


# recode no-responses
data$nr <- as.numeric(data$rt == 1500);


# check differences in no-responses between conditions
responsedesc <- aggregate(nr ~ list:pool, data, table);
responsestat <- chisq.test(responsedesc$nr[1:2], simulate.p.value = TRUE);


# check differences in errors
errordesc <- aggregate(c ~ list:pool, data, table);
errorstat <- chisq.test(errordesc$c[1:2], simulate.p.value = TRUE);


# remove no-responses
data.controlled <- subset(data, nr == 0);


# remove errors
data.controlled <- subset(data.controlled, c == 1);


# control learning
learning.hr <- t.test(data$c, mu = 1/2, alternative = "greater"); 
# ceiling effect! with mean of .96


# outlier removal by ppn by condition using MAD approach
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, mad, constant=(-1/(sqrt(2)*erfcinv(3/2)))), c('ppn', 'condition', 'mad_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- setNames(aggregate(rt ~ ppn:condition, data.controlled, median), c('ppn', 'condition', 'median_by_ppncond'));
data.controlled <- merge(data.controlled, data.controlled.mad, by=c('ppn', 'condition'));
data.controlled.mad <- subset(data.controlled, rt >= median_by_ppncond - (3 * mad_by_ppncond) & rt <= median_by_ppncond + (3 * mad_by_ppncond));


# jot down data loss (total + stage-wise)
data.controlled.loss.total <- (1 - NROW(data.controlled.mad) / NROW(data)) * 100;
data.controlled.loss.noresponse <- (1 - NROW(data.controlled) / NROW(data)) * 100;
data.controlled.loss.mad <- (1 - NROW(data.controlled.mad) / NROW(data.controlled)) * 100;


### 2: modelling of data
ggplot(aggregate(c ~ condition:rep, data.controlled.mad, NROW), aes(x = rep, y = c, group = condition)) + geom_bar(stat = "identity") + facet_wrap(~condition)


# make contrast matrix for condition
data.controlled.mad$ConditionM <- factor(data.controlled.mad$condition);
contrasts(data.controlled.mad$ConditionM) <- MASS::contr.sdif(levels(data.controlled.mad$condition));


# transform i
data.controlled.mad$Iz <- (data.controlled.mad$i - mean(data.controlled.mad$i)) / sd(data.controlled.mad$i);


# make contrast matrix for RepM
data.controlled.mad$RepM <- factor(data.controlled.mad$rep);
contrasts(data.controlled.mad$RepM) <- MASS::contr.sdif(levels(data.controlled.mad$RepM));


# fit most basic model
lme.basic <- lmer(1/rt ~ RepM + ConditionM + ConditionM:rep + Iz + (1|ppn), data.controlled.mad);


# tests
plot_model(lme.basic, type = "pred", terms = c("RepM", "ConditionM"))



# add intercept by spkr
lme.complex.1 <- lmer(1/rt ~ RepM + ConditionM + ConditionM:rep + Iz + (1|ppn), data.controlled.mad);


# add intercept for location
lme.complex.1 <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn) + (1|loc), data.controlled.mad);
isSingular(lme.complex.1); # false
cmp.complex.1 <- anova(lme.basic, lme.complex.1); # better


# add slope for repetition by ppn:id to account for a (potential) order effect of word repetitions
lme.complex.2 <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn) + (1|loc) + (0+rep|ppn:id), data.controlled.mad);
isSingular(lme.complex.2); # false
cmp.complex.2 <- anova(lme.complex.1, lme.complex.2); # better


# add slope for time by ppn
lme.complex.3 <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn) + (1|loc) + (0+rep|ppn:id) + (0+Iz|ppn), data.controlled.mad);
isSingular(lme.complex.3); # false
cmp.complex.3 <- anova(lme.complex.2, lme.complex.3); # better


# add slope for time by ppn:condition
lme.complex.4 <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn) + (1|loc) + (0+rep|ppn:id) + (0+Iz|ppn) + (0+Iz|ppn:condition), data.controlled.mad);
isSingular(lme.complex.6); # false
cmp.complex.4 <- anova(lme.complex.3, lme.complex.4); # better


# add slope for condition by ppn
lme.complex.5 <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn) + (1|loc) + (0+rep|ppn:id) + (0+Iz|ppn:condition) + (0+condition|ppn), data.controlled.mad);
# fails to converge


# keep best
lme.best <- lme.complex.4;
lme.best.sum <- summary(lme.best);


# do some visual inspections
plot(lme.best); # a-ok
qqnorm(resid(lme.best)); # a-ok
qqline(resid(lme.best)); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | ppn, abline = 0); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | loc, abline = 0); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | condition, abline = 0); # a-ok


# run glhts on coefficients
lme.best.glht <- glht(lme.best, rbind(S1_S2 = c(0, 0, 0,
                                                0, 1,
                                                0, -1,
                                                0, 0,
                                                0, 0,
                                                0),
                                      L1P1_L3P3 = c(0, 0, 0,
                                                    1, 1,
                                                    0, 0,
                                                    0, 0,
                                                    0, 0,
                                                    0),
                                      L2P2_L3P3 = c(0, 0, 0,
                                                    0, 0,
                                                    1, 1,
                                                    0, 0,
                                                    0, 0,
                                                    0),
                                      V1_V2 = c(0, 0, 0,
                                                1, 1,
                                                -1, -1,
                                                0, 0,
                                                0, 0,
                                                0),
                                      V_MS2 = c(0, 0, 0, 
                                                0, 0,
                                                1, 0,
                                                0, 0,
                                                0, -1,
                                                0)))
lme.best.glht.sum <- summary(lme.best.glht, test = adjusted('holm'));


# compute CIs for final model
lme.best.cis <- confint(lme.best, method = "profile");


# save everything (in an inefficient way but ok)
save.image(file=file.path(outdir, "run_4afc.RData"));


### 3: visualise
load(file=file.path(outdir, "run_4afc.RData"));

lme.best.dat <- data.controlled.mad;
lme.best.dat$fitted <- fitted(lme.best);
lme.best.dat$fittedRT <- 10 ** lme.best.dat$fitted; # transform back for plotting
lme.best.ppnstats <- aggregate(fittedRT ~ ppn + condition, lme.best.dat, mean);
lme.best.repstats <- aggregate(fittedRT ~ ppn + rep, lme.best.dat, mean);


plt.main <- subset(lme.best.ppnstats, condition == 'L1P1' |
                                      condition == 'L1P2' |
                                      condition == 'L1P3' |
                                      condition == 'L3P3' |
                                      condition == 'L2P1' |
                                      condition == 'L2P3' |
                                      condition == 'L2P2');
plt.main$condition <- factor(plt.main$condition, levels = c('L1P1', 'L1P2', 'L1P3', 'L2P1', 'L2P2', 'L2P3', 'L3P3'));
plt.rep <- lme.best.repstats;

plt.coef <- data.frame(emmeans(lme.best, "ConditionM"));
plt.coef$rtmu <- 10 ** plt.coef$emmean;
plt.coef$rtsd <- (10 ** (plt.coef$emmean + plt.coef$SE) - 10 ** (plt.coef$emmean - plt.coef$SE)) / 2;
plt.coef$condition <- factor(plt.coef$ConditionM, levels = c('L1P1', 'L1P2', 'L1P3', 'L2P1', 'L2P2', 'L2P3', 'L3P3'));

plt2.coef <- data.frame(emmeans(lme.best, "RepM"));
plt2.coef$rtmu <- 10 ** plt2.coef$emmean;
plt2.coef$rtsd <- (10 ** (plt2.coef$emmean + plt2.coef$SE) - 10 ** (plt2.coef$emmean - plt2.coef$SE)) / 2;
plt2.coef$rep <- factor(plt2.coef$RepM);


plt.main.l1 <- subset(plt.main, condition == 'L1P1' | 
                                condition == 'L1P3' |
                                condition == 'L3P3');
plt.coef.l1 <- subset(plt.coef, condition == 'L1P1' | 
                                condition == 'L1P3' | 
                                condition == 'L3P3');


plt.main.l2 <- subset(plt.main, condition == 'L2P2' | 
                                condition == 'L2P3' |
                                condition == 'L3P3');
plt.coef.l2 <- subset(plt.coef, condition == 'L2P2' | 
                                condition == 'L2P3' |
                                condition == 'L3P3');


plt.main.msl1 <- subset(plt.main, condition == 'L1P2' |
                                  condition == 'L1P3');
plt.coef.msl1 <- subset(plt.coef, condition == 'L1P2' |
                                  condition == 'L1P3');


plt.main.msl2 <- subset(plt.main, condition == 'L2P1' |
                                  condition == 'L2P3');
plt.coef.msl2 <- subset(plt.coef, condition == 'L2P1' |
                                  condition == 'L2P3');


# create plot for L1P1 < L1P3 < L3P3
l1 <-
ggplot() + 
  # add fitted conditional responses by participant
  geom_line(data = plt.main.l1, aes(x = condition, y = fittedRT, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.l1, aes(x = condition, y = fittedRT, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) + 
  
  # add emmeans per condition
  geom_line(data = plt.coef.l1, aes(x = condition, y = rtmu, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.l1, aes(x = condition, ymin = rtmu-rtsd, ymax = rtmu+rtsd, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.l1, aes(x = condition, y = rtmu, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add comparisons
  geom_signif(data = plt.main.l1, aes(x = condition, y = fittedRT, annotations = '*'), manual = TRUE, annotations = '.001', y_position = 3075, xmin=1, xmax=2, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.l1, aes(x = condition, y = fittedRT, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 3275, xmin=2, xmax=3, size = 0.2, textsize=3.0) + 
  
  # set limit
  ylim(1000, 3350) + 
  
  # add labels
  labs(x = TeX("Low variability"), y = "RT (ms)") + 
  scale_x_discrete(labels = c('veridical', 'stat. word', 'control')) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.3, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_4afc_l1p1_l1p3_l3p3.svg"), width=3, height=4, plot=l1)
ggsave(file=file.path(outdir, "run_4afc_l1p1_l1p3_l3p3.png"), width=3, height=4, plot=l1)


# create plot for L2P2 ~ L2P3 < L3P3
l2 <-
ggplot() + 
  # add fitted conditional responses by participant
  geom_line(data = plt.main.l2, aes(x = condition, y = fittedRT, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.l2, aes(x = condition, y = fittedRT, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) + 
  
  # add emmeans per condition
  geom_line(data = plt.coef.l2, aes(x = condition, y = rtmu, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.l2, aes(x = condition, ymin = rtmu-rtsd, ymax = rtmu+rtsd, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.l2, aes(x = condition, y = rtmu, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add comparisons
  geom_signif(data = plt.main.l2, aes(x = condition, y = fittedRT, annotations = 'n.s.'), manual = TRUE, annotations = '.001', y_position = 2875, xmin=1, xmax=2, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.l2, aes(x = condition, y = fittedRT, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 3075, xmin=2, xmax=3, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.l2, aes(x = condition, y = fittedRT, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 3275, xmin=1, xmax=3, size = 0.2, textsize=3.0) + 
  
  # set limit
  ylim(1000, 3350) + 
  
  # add labels
  labs(x = TeX("High variability"), y = "RT (ms)") + 
  scale_x_discrete(labels = c('veridical', 'stat. word', 'control')) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.6, end = 0.65, direction = -1) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_4afc_l2p2_l2p3_l3p3.svg"), width=3, height=4, plot=l2)
ggsave(file=file.path(outdir, "run_4afc_l2p2_l2p3_l3p3.png"), width=3, height=4, plot=l2)


# create plot for L1P2 < L1P3 & L2P1 ~ L2P3
ms <- 
ggplot() + 
  # add fitted conditional responses by participant (l1)
  geom_line(data = plt.main.msl1, aes(x = condition, y = fittedRT, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.msl1, aes(x = condition, y = fittedRT, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) + 
  
  # add fitted conditional responses by participant (l2)
  geom_line(data = plt.main.msl2, aes(x = condition, y = fittedRT, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.msl2, aes(x = condition, y = fittedRT, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) + 
  
  # add emmeans per condition (l1)
  geom_line(data = plt.coef.msl1, aes(x = condition, y = rtmu, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.msl1, aes(x = condition, ymin = rtmu-rtsd, ymax = rtmu+rtsd, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.msl1, aes(x = condition, y = rtmu, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add emmeans per condition (l1)
  geom_line(data = plt.coef.msl2, aes(x = condition, y = rtmu, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.msl2, aes(x = condition, ymin = rtmu-rtsd, ymax = rtmu+rtsd, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.msl2, aes(x = condition, y = rtmu, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add comparisons
  geom_signif(data = plt.main.msl1, aes(x = condition, y = fittedRT, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 3200, xmin=1, xmax=2, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.msl2, aes(x = condition, y = fittedRT, annotations = 'n.s.'), manual = TRUE, annotations = '.001', y_position = 3200, xmin=3, xmax=4, size = 0.2, textsize=3.0) + 
  
  # set limit
  ylim(1000, 3350) + 
  
  # add labels
  labs(x = '', y = "RT (ms)") + 
  scale_x_discrete(labels = c('stat. md.', 'stat. word', 'stat. md.', 'stat. word')) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.3, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_4afc_ms_ws.svg"), width=4, height=4, plot=ms)
ggsave(file=file.path(outdir, "run_4afc_ms_ws.png"), width=4, height=4, plot=ms)

reps <- 
  ggplot() + 
  
  # add fitted conditional responses by participant
  geom_line(data = plt.rep, aes(x = rep, y = fittedRT, group = ppn, color = rep), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.rep, aes(x = rep, y = fittedRT, group = ppn, color = rep, shape = as.factor(rep)), size = .8, show.legend = FALSE) + 
  
  # add emmeans per condition
  geom_line(data = plt2.coef, aes(x = as.numeric(rep), y = rtmu, group = 1, color = as.numeric(rep)), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt2.coef, aes(x = as.numeric(rep), ymin = rtmu-rtsd, ymax = rtmu+rtsd, group = 1, color = as.numeric(rep)), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) +
  geom_point(data = plt2.coef, aes(x = as.numeric(rep), y = rtmu, group = 1, color = as.numeric(rep), shape = as.factor(rep)), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add comparisons
  geom_signif(data = plt.rep, aes(x = as.numeric(rep), y = fittedRT, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 3250, xmin=1, xmax=2, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.rep, aes(x = as.numeric(rep), y = fittedRT, annotations = '*'), manual = TRUE, annotations = '.001', y_position = 3050, xmin=2, xmax=3, size = 0.2, textsize=3.0) + 
  
  # set limit
  ylim(1000, 3350) + 
  
  # add labels
  labs(x = 'Repetition', y = "RT (ms)") + 
  scale_x_continuous(breaks=c(1,2,3)) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = FALSE, alpha = 0.4, begin = 0.3, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_4afc_reps.svg"), width=4, height=4, plot=reps)
ggsave(file=file.path(outdir, "run_4afc_reps.png"), width=4, height=4, plot=reps)
