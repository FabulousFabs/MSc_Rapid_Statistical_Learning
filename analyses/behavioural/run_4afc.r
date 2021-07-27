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
file <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_4AFC_False.txt"; # collection to load
outdir <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/out/";


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
data$s <- factor(data$s);                             # factor: speaker sex
data$o1 <- factor(data$o1);                           # factor: option1
data$o2 <- factor(data$o2);                           # factor: option2
data$o3 <- factor(data$o3);                           # factor: option3
data$o4 <- factor(data$o4);                           # factor: option4
data$c <- as.numeric(as.character(data$c));           # continuous: correct response (1 = TRUE, 0 = FALSE)
data$r <- factor(data$r);                             # factor: response given
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$rtl <- log10(as.numeric(as.character(data$rt))); # continuous: reaction time (log10)
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

for (it in data$unique) {
  data[data$unique == it,]$rep = NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id));
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


# recode correct location in grid
fn.recode_od <- function(r) { 
  if (r[[9]] == r[[11]]) { return('top_left'); } 
  if (r[[9]] == r[[12]]) { return('bottom_left'); } 
  if (r[[9]] == r[[13]]) { return('top_right'); } 
  return('bottom_right'); 
};
data$loc <- factor(apply(data, MARGIN=1, FUN=fn.recode_od)); # factor: correct option position in grid


# check differences in no-responses between conditions
responsedesc <- aggregate(r ~ list:pool, data, table);
responsestat <- chisq.test(responsedesc$r[1:9], simulate.p.value = TRUE);


# remove no-responses
data.controlled <- subset(data, r == 1 | r == 2 | r == 3 | r == 4);


# remove errors
data.controlled <- subset(data.controlled, c == 1);


# control learning
learning.hr <- t.test(data$c, mu = 1/4, alternative = "greater"); 
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
# run last checks of data; this is an important step because we _know_ that we only sampled items from each condition (i.e., we are now using 20 items per condition rather than 80, as is the case in, for example, the MEG task) - we landed on this compromise to even make this study doable time-wise (we were already hitting 3hrs per session), but this _might_ create bias in what words/speakers occur in which conditions, on average, which has some implications for the kinds of random effects we can fit in the 4AFC model
words_by_cond_plot <- ggplot(aggregate(rt ~ condition:id, data.controlled.mad, NROW), aes(x = id, y = rt, group = condition)) + geom_bar(stat = "identity");
words_by_cond_plot + facet_wrap(~condition);
# this shows pretty clearly that this random effect is unbalanced in the design and we should, as such, not fit it in our models


# let's look at the same problem for speakers, too
spkrs_by_cond_plot <- ggplot(aggregate(rt ~ condition:spkr, data.controlled.mad, NROW), aes(x = spkr, y = rt, group = condition)) + geom_bar(stat = "identity");
spkrs_by_cond_plot + facet_wrap(~condition);
# and this, too, shows that it's a little bit unbalanced (particularly between speakers 4 & 10) - this could make for a real problem in our random effects structure, i'm afraid. i think it's best to leave out intercepts by word id or speaker in this model - we had that in the MEG data, at least, but the design here doesnt really allow for it, i'm afraid


# make contrast matrix for condition
M <- rbind(c(1, 0, -1, 0, 0, 0, 0, 0, 0),
           c(0, 0, 1, 0, 0, 0, 0, 0, -1),
           c(0, 0, 0, 0, 1, -1, 0, 0, 0),
           c(0, 0, 0, 0, 0, 1, 0, 0, -1),
           c(0, 0, 0, 0, 0, 0, 0, 1, -1),
           c(0, 0, 0, 0, 0, 0, 1, 0, -1),
           c(0, 1, -1, 0, 0, 0, 0, 0, 0),
           c(0, 0, 0, 1, 0, -1, 0, 0, 0)
           );
rownames(M) <- c('L1P1_L1P3', 'L1P3_L3P3', 'L2P2_L2P3', 'L2P3_L3P3', 'L3P2_L3P3', 'L3P1_L3P3', 'L1P2_L1P3', 'L2P1_L2P3');
colnames(M) <- levels(data.controlled.mad$condition);
CM <- ginv(M);
dimnames(CM) <- rev(dimnames(M));
data.controlled.mad$ConditionM <- factor(data.controlled.mad$condition);
contrasts(data.controlled.mad$ConditionM) <- CM;


# make contrast matrix for RepM
data.controlled.mad$Iz <- (data.controlled.mad$i - mean(data.controlled.mad$i)) / sd(data.controlled.mad$i);
data.controlled.mad$RepM <- factor(data.controlled.mad$rep);
contrasts(data.controlled.mad$RepM) <- MASS::contr.sdif(levels(data.controlled.mad$RepM));


# fit most basic model
lme.basic <- lmer(rtl ~ RepM + ConditionM + Iz + (1|ppn), data.controlled.mad);


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


plt.main <- subset(lme.best.ppnstats, condition == 'L1P1' | 
                                      condition == 'L1P3' |
                                      condition == 'L3P3' |
                                      condition == 'L2P3' |
                                      condition == 'L2P2');
plt.main$condition <- factor(plt.main$condition, levels = c('L1P1', 'L1P3', 'L2P2', 'L2P3', 'L3P3'));


plt.coef <- data.frame(emmeans(lme.best, "ConditionM"));
plt.coef$rtmu <- 10 ** plt.coef$emmean;
plt.coef$rtsd <- (10 ** (plt.coef$emmean + plt.coef$SE) - 10 ** (plt.coef$emmean - plt.coef$SE)) / 2;
plt.coef$condition <- factor(plt.coef$ConditionM, levels = c('L1P1', 'L1P3', 'L2P2', 'L2P3', 'L3P3'));


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

plt.main.st <- subset(plt.main, condition == 'L1P3' |
                                condition == 'L2P3');
plt.coef.st <- subset(plt.coef, condition == 'L1P3' |
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
  labs(x = TeX("List_1"), y = "RT (ms)") + 
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
  labs(x = TeX("List_2"), y = "RT (ms)") + 
  scale_x_discrete(labels = c('veridical', 'stat. word', 'control')) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.6, end = 0.65, direction = -1) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_4afc_l2p2_l2p3_l3p3.svg"), width=3, height=4, plot=l2)
ggsave(file=file.path(outdir, "run_4afc_l2p2_l2p3_l3p3.png"), width=3, height=4, plot=l2)

