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
file <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/union_MEG_False.txt"; # collection to load
outdir <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/out/";


system("module unload python && module load python/3.4.2 && cd /project/3018012.23/git/analyses/behavioural/ && python prep_aggregate.py --none --MEG"); # collect data on /project/


### 1: load, recode and preprocess data
data <- read.delim(file, header = TRUE, sep = "\t", dec=".");


data$ppn <- factor(data$ppn);                         # factor: participant id
data$id <- factor(data$id);                           # factor: item id
data$spkr <- factor(data$spkr);                       # factor: speaker id
data$var <- factor(data$var);                         # factor: speaker:item variant
data$dur <- as.numeric(as.character(data$dur));       # continuous: duration
data$f <- as.character(data$f);                       # string: file
data$pool <- factor(data$pool);                       # factor: speaker pool
data$list <- factor(data$list);                       # factor: item list
data$def <- factor(data$def);                         # factor: definition id
data$s <- factor(data$s);                             # factor: speaker sex
data$t <- factor(data$t);                             # factor: option1
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$r <- factor(data$r);                             # factor: option2
data$c <- as.numeric(as.character(data$c));           # factor: correct response (1 = TRUE, 0 = FALSE)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$rtl <- log10(as.numeric(as.character(data$rt))); # continuous: reaction time (log10)
data$unique <- seq_along(data$ppn);                   # unique identifier (for recoding)


# recode repetitions
data$rep <- 0;

#for (it in data$unique) {
#  data[data$unique == it,]$rep = NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == #data[data$unique == it,]$id));
#}
for (it in data$unique) {
  data[data$unique == it,]$rep = NROW(subset(data, ppn == data[data$unique == it,]$ppn & unique <= it & id == data[data$unique == it,]$id & list == data[data$unique == it,]$list & pool == data[data$unique == it,]$pool));
}


# recode conditions
data$condition <- 0;
data[data$list == 1 & data$pool == 1,]$condition <- 'L1P1';
data[data$list == 1 & data$pool == 3,]$condition <- 'L1P3';
data[data$list == 2 & data$pool == 2,]$condition <- 'L2P2';
data[data$list == 2 & data$pool == 3,]$condition <- 'L2P3';
data$condition <- factor(data$condition);


# check differences in no-responses between conditions
responsedesc <- aggregate(r ~ list:pool, data, table);
responsestat <- chisq.test(responsedesc$r[1:4]);


# remove no-responses
data.controlled <- subset(data, r == 1 | r == 2);


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
# prep contrasts
data.controlled.mad$ConditionM <- data.controlled.mad$condition;
data.controlled.mad$ConditionM <- factor(data.controlled.mad$ConditionM, levels = c('L1P1', 'L1P3', 'L2P3', 'L2P2'));
data.controlled.mad$RepM <- data.controlled.mad$rep;
data.controlled.mad$RepM <- factor(data.controlled.mad$RepM);
data.controlled.mad$Iz <- (data.controlled.mad$i - mean(data.controlled.mad$i)) / sd(data.controlled.mad$i); # z-score time data to prevent large eigenvalue issues


# contrast matrix for ConditionM
# in the paper we describe this as also being .sdir and that's technically true given that here we're doing this because the levels are just not in order and i wrote this instead, for some reason. it's mathematically equivalent and i cba to change it for aesthetic value right now.
M <- rbind(c(1, -1, 0, 0),
           c(0, 0, -1, 1),
           c(0, 1, 0, -1));
rownames(M) <- c('L1_v-s', 'L2_v-s', 'S1-S2');
colnames(M) <- levels(data.controlled.mad$ConditionM);
CM <- ginv(M);
dimnames(CM) <- rev(dimnames(M));
contrasts(data.controlled.mad$ConditionM) <- CM;


# contrast matrix for RepM
contrasts(data.controlled.mad$RepM) <- MASS::contr.sdif(levels(data.controlled.mad$RepM));


# fit most basic model
lme.basic <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn), data.controlled.mad);


# add intercepts by type of question and definition because some combinations are naturally more difficult/easy to answer
lme.complex.1 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def), data.controlled.mad);
isSingular(lme.complex.1) # false
cmp.complex.1 <- anova(lme.basic, lme.complex.1); # better


# add intercepts by precise combination of word:speaker:variant because no matter how hard we tried to control pronunciations, there will always be some inherent differences here
lme.complex.2 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var), data.controlled.mad);
isSingular(lme.complex.2); # false
cmp.complex.2 <- anova(lme.complex.1, lme.complex.2); # better


# add slope by condition:repetition
lme.complex.3 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+condition:rep|ppn), data.controlled.mad);
isSingular(lme.complex.3); # true, move on


# add slope by condition only
lme.complex.3 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+condition|ppn), data.controlled.mad);
isSingular(lme.complex.3) # true, move on


# add slope by repetition only
lme.complex.3 <- lmer(rt ~ RepM*ConditionM + Iz +  (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+rep|ppn), data.controlled.mad);
isSingular(lme.complex.3); # false
cmp.complex.3 <- anova(lme.complex.2, lme.complex.3); # better


# add slope by time only
lme.complex.4 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+rep|ppn) + (0+Iz|ppn), data.controlled.mad);
isSingular(lme.complex.3); # true, move on


# add slope for time:rep by ppn
lme.complex.4 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+rep|ppn) + (0+Iz:rep|ppn), data.controlled.mad);
isSingular(lme.complex.4); # false
cmp.complex.4 <- anova(lme.complex.3, lme.complex.4); # better


# add slope by time by condition
lme.complex.5 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+rep|ppn) + (0+Iz:rep|ppn) + (0+Iz:condition|ppn), data.controlled.mad);
isSingular(lme.complex.5); # true, move on


# add slope by time by condition by repetition
lme.complex.5 <- lmer(rt ~ RepM*ConditionM + Iz + (1|ppn) + (1|t:def) + (1|id:spkr:var) + (0+rep|ppn) + (0+Iz:rep|ppn) + (0+Iz:condition:rep|ppn), data.controlled.mad);
isSingular(lme.complex.5); # true, move on


# keep best
lme.best <- lme.complex.4;
summary(lme.best);


# do some visual inspection of the model quality
plot(lme.best); # a-ok
qqnorm(resid(lme.best)); # a-ok
qqline(resid(lme.best)); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | ppn, abline = 0); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | t:def, abline = 0); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | id); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | spkr); # a-ok
plot(lme.best, resid(., scaled = TRUE) ~ fitted(.) | rep); # a-ok


# run glhts
lme.best.glht <- glht(lme.best, rbind(L1_L2 = c(0, 0, 0, 0, 1, -1, 0, 0,
                                                0, 0, 0,
                                                0, 0, 0,
                                                0, 0, 0),
                                      
                                      EVOLU = c(0, 0, 0, 0, 0, 0, 0, 0,
                                                1, 1, 1,
                                                -1, -1, -1,
                                                0, 0, 0)));
lme.best.glht.sum <- summary(lme.best.glht, test = adjusted('holm'));


# compute CIs for final model
lme.best.cis <- confint(lme.best, method = "profile");


# save everything (in an inefficient way but ok)
save.image(file=file.path(outdir, "run_meg.RData"));


### 3: visualise
load(file=file.path(outdir, "run_meg.RData"));


lme.best.dat <- data.controlled.mad;
lme.best.dat$fitted <- fitted(lme.best);
lme.best.ppnstats <- aggregate(fitted ~ ppn + condition, lme.best.dat, mean);
lme.best.ppnstats$condition <- factor(lme.best.ppnstats$condition, levels=c('L1P1', 'L1P3', 'L2P2', 'L2P3'));


plt.main.l1 <- subset(lme.best.ppnstats, condition == 'L1P1' |
                                         condition == 'L1P3');
plt.main.l2 <- subset(lme.best.ppnstats, condition == 'L2P2' |
                                         condition == 'L2P3');


plt.coef <- data.frame(emmeans(lme.best, "ConditionM"));
plt.coef$condition <- factor(plt.coef$ConditionM, levels=c('L1P1', 'L1P3', 'L2P2', 'L2P3'));


plt.coef.l1 <- subset(plt.coef, condition == 'L1P1' |
                                condition == 'L1P3');
plt.coef.l2 <- subset(plt.coef, condition == 'L2P2' |
                                condition == 'L2P3');


ver_stat <-
  ggplot () + 
  # add fitted conditional responses by participant (L1)
  geom_line(data = plt.main.l1, aes(x = condition, y = fitted, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.l1, aes(x = condition, y = fitted, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) +
  
  # add fitted conditional responses by participant (L2)
  geom_line(data = plt.main.l2, aes(x = condition, y = fitted, group = ppn, color = condition), size = .4, show.legend = FALSE) + 
  geom_point(data = plt.main.l2, aes(x = condition, y = fitted, group = ppn, color = condition, shape = condition), size = .8, show.legend = FALSE) + 

  # add emmeans per condition (L1)
  geom_line(data = plt.coef.l1, aes(x = condition, y = emmean, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.l1, aes(x = condition, ymin = emmean-SE, ymax = emmean+SE, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.l1, aes(x = condition, y = emmean, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) + 
  
  # add emmeans per condition (L2)
  geom_line(data = plt.coef.l2, aes(x = condition, y = emmean, group = 1, color = condition), size = 1.0, alpha = 1.0, show.legend = FALSE) + 
  geom_errorbar(data = plt.coef.l2, aes(x = condition, ymin = emmean-SE, ymax = emmean+SE, group = 1, color = condition), size = 1, width = .08, alpha = 1.0, show.legend = FALSE) + 
  geom_point(data = plt.coef.l2, aes(x = condition, y = emmean, group = 1, color = condition, shape = condition), size = 2, alpha = 1.0, show.legend = FALSE) +
  
  # set limit
  ylim(400, 2300) + 
  
  # add comparisons
  geom_signif(data = plt.main.l1, aes(x = condition, y = fitted, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 2000, xmin=1, xmax=2, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.l1, aes(x = condition, y = fitted, annotations = '*'), manual = TRUE, annotations = '.05', y_position = 2000, xmin=3, xmax=4, size = 0.2, textsize=3.0) + 
  geom_signif(data = plt.main.l1, aes(x = condition, y = fitted, annotations = '***'), manual = TRUE, annotations = '.001', y_position = 2200, xmin=2, xmax=4, size = 0.2, textsize=3.0) + 
  
  # add labels
  labs(x = '', y = "RT (ms)") + 
  scale_x_discrete(labels = c('veridical', 'stat. word', 'veridical', 'stat. word')) + 
  
  # stylise
  scale_fill_viridis() + 
  scale_color_viridis(discrete = TRUE, alpha = 0.4, begin = 0.3, end = 0.6) + 
  theme_bw() + 
  theme(text = element_text(family = "Roboto"))
ggsave(file=file.path(outdir, "run_meg_ver_stat.svg"), width=4, height=4, plot=ver_stat)
ggsave(file=file.path(outdir, "run_meg_ver_stat.png"), width=4, height=4, plot=ver_stat)
