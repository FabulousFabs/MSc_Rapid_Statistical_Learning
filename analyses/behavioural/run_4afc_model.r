# script to run our behavioural analyses (that, unfortunately,
# i wrote before i saw that there's a julia package of lme4 - 
# that would've been the dream to work with, praise be julia)

library(tidyverse);
library(ggpubr);
library(rstatix);
library(latex2exp);
library(ggplot2);
library(nortest);
library(car);
library(lme4);
library(lmerTest);
library(effects);
library(multcomp);
library(emmeans);
library(cowplot);
library(raincloudplots);
library(dplyr);
library(ggpubr);
library(gtable);
library(psycho);
library(gtools);
library(caret);

setwd("/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/")
source("./R_rainclouds.r")

file <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/aggregate.txt"; # collection to load
afc_chance <- 1 / 4; # chance level of performance in 4AFC
cutoff_sd <- 2; # standard deviations beyond which we classify outliers

### 1: load and prepare data
data <- read.delim(file, header = TRUE, sep = "\t", dec=".");

data$ppn <- factor(data$ppn);                         # factor: participant id
data$spkr <- factor(data$spkr);                       # factor: speaker id
data$id <- factor(data$id);                           # factor: item id
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
data$cor <- as.numeric(as.character(data$cor));       # factor: correct response (1 = TRUE, 0 = FALSE)
data$r <- factor(data$cor);                           # factor: chosen option
data$rt <- as.numeric(as.character(data$rt));         # continuous: reaction time (ms)
data$i <- as.numeric(as.character(data$i));           # continuous: time progression
data$rtl <- log10(as.numeric(as.character(data$rt))); # continuous: reaction time (log10)
fn.recode_od <- function(r) { 
  if (r[[9]] == r[[11]]) { return('top_left'); } 
  else if (r[[9]] == r[[12]]) { return('bottom_left'); } 
  else if (r[[9]] == r[[13]]) { return('top_right'); } 
  return('bottom_right'); 
};
data$od <- factor(apply(data, MARGIN=1, FUN=fn.recode_od)); # factor: correct option position in grid

### 2: control learning
hr.total.t <- t.test(data$cor, mu = afc_chance, alternative = "greater"); # one-sided t-test for HR > chance
hr.total.t

hr.by_participant <- aggregate(data$cor, list(data$ppn), mean); # hit rate by participant
hr.by_item <- aggregate(data$cor, list(data$spkr), mean);       # hit rate by item (mislabelled)
hr.by_speaker <- aggregate(data$cor, list(data$id), mean);      # hit rate by speaker (mislabelled)

# create plots by participant to check for outliers
ggplot(data = hr.by_participant) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr.total.t$estimate, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Participant") +
  ggtitle(sprintf("Learning outcomes by participant, p=%.3f.", hr.total.t$p.value)) + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggsave('/users/fabianschneider/desktop/university/master/dissertation/project/write-up/graphics_general/stash/beh/pilot_hitrate-byppn_withincontrol_rtl.png')

# create plots by items to check for outliers
ggplot(data = hr.by_item) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr.total.t$estimate, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Item") +
  ggtitle("Learning outcomes by item.") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# create plots by speakers for outliers
ggplot(data = hr.by_speaker) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr.total.t$estimate, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Speaker") +
  ggtitle("Learning outcomes by speaker,") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

# filter data (if applicable)
# note that, due to the nature of the design, we cannot
# apply filters for particular speakers; they had all
# better be okay. the data loss would be way beyond
# anything we could work with
drop.participants <- c(); # specify participants (if any) to drop from analyses because of poor performance
drop.items <- c(); # specify items (if any) to drop from analyses because of poor performance
data.controlled <- subset(data, !(ppn %in% drop.participants | spkr %in% drop.items)); # apply filter

### 3: prepare data
data.controlled.hits <- subset(data.controlled, cor == 1); # correct response filter

# quick comment here:
# a lot of the following visualisations
# and analyses are kind of pointless
# given that we have a pretty strong
# idea of what we want and how we want
# to get there (I mean, for example,
# it just doesn't make sense for us
# to SD control RTL data). generally,
# we do a pretty comprehensive look
# into all the possible combinations
# here nevertheless just for the sake
# of completeness.
# skip reading this for sanity

rt.mu.total <- mean(data.controlled.hits$rt); # RT mean
rtl.mu.total <- mean(data.controlled.hits$rtl); # RTL mean
rt.sd.total <- sd(data.controlled.hits$rt); # RT sd
rtl.sd.total <- sd(data.controlled.hits$rtl); # RTL sd

rt.mu.by_participant <- setNames(aggregate(data.controlled.hits$rt, list(data.controlled.hits$ppn), mean), c("ppn", "rt_mu_ppn")); # RT mean by participant
rtl.mu.by_participant <- setNames(aggregate(data.controlled.hits$rtl, list(data.controlled.hits$ppn), mean), c("ppn", "rtl_mu_ppn")); # RTL mean by participant
rt.sd.by_participant <- setNames(aggregate(data.controlled.hits$rt, list(data.controlled.hits$ppn), sd), c("ppn", "rt_sd_ppn")); # RT sd by participant
rtl.sd.by_participant <- setNames(aggregate(data.controlled.hits$rtl, list(data.controlled.hits$ppn), sd), c("ppn", "rtl_sd_ppn")); # RTL sd by participant
data.controlled.hits <- merge(data.controlled.hits, rt.mu.by_participant, by="ppn"); # merge mean for easy access (RT)
data.controlled.hits <- merge(data.controlled.hits, rtl.mu.by_participant, by="ppn"); # merge mean for easy access (RTL)
data.controlled.hits <- merge(data.controlled.hits, rt.sd.by_participant, by="ppn"); # merge standard deviation for easy access (RT)
data.controlled.hits <- merge(data.controlled.hits, rtl.sd.by_participant, by="ppn"); # merge standard deviation for easy access (RTL)

# filter data
data.controlled.hits.between <- subset(data.controlled.hits, rt <= (rt.mu.total + (cutoff_sd * rt.sd.total)) & 
                                                             rt >= (rt.mu.total - (cutoff_sd * rt.sd.total)));
data.controlled.hits.within <- subset(data.controlled.hits, rt <= (rt_mu_ppn + (cutoff_sd * rt_sd_ppn)) &
                                                            rt >= (rt_mu_ppn - (cutoff_sd * rt_sd_ppn)));
data.controlled.hits.both <- subset(data.controlled.hits.within, rt <= (rt.mu.total + (cutoff_sd * rt.sd.total)) & 
                                      rt >= (rt.mu.total - (cutoff_sd * rt.sd.total)));
data.controlled.hits.between.by_rtl <- subset(data.controlled.hits, rtl <= (rtl.mu.total + (cutoff_sd * rtl.sd.total)) &
                                                                    rtl >= (rtl.mu.total - (cutoff_sd * rtl.sd.total)));
data.controlled.hits.within.by_rtl <- subset(data.controlled.hits, rtl <= (rtl_mu_ppn + (cutoff_sd * rtl_sd_ppn)) & 
                                                                   rtl >= (rtl_mu_ppn - (cutoff_sd * rtl_sd_ppn)));
data.controlled.hits.both.by_rtl <- subset(data.controlled.hits.within.by_rtl, rtl <= (rtl.mu.total + (cutoff_sd * rtl.sd.total)) &
                                                                               rtl >= (rtl.mu.total - (cutoff_sd * rtl.sd.total)));

# create plots to check for outliers pre-filtering
hist(data.controlled.hits$rt, xlab = "RT (ms)")
ggplot(data.controlled.hits, aes(x = rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits$rt)

# create plots to check for outliers post-filtering (between)
hist(data.controlled.hits.between$rt, xlab = "RT (ms)")
ggplot(data.controlled.hits.between, aes(x = rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.between$rt)

# create plots to check for outliers post-filtering (within)
hist(data.controlled.hits.within$rt, xlab = "RT (ms)")
ggplot(data.controlled.hits.within, aes(x = rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.within$rt)

# create plots to check for outliers post-filtering (both)
hist(data.controlled.hits.both$rt, xlab = "RT (ms)")
ggplot(data.controlled.hits.both, aes(x = rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.both$rt)

# create plots to check for outliers pre-filtering (RTL)
hist(data.controlled.hits$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = .003)
ggqqplot(data.controlled.hits$rtl);

# create plots to check for outliers post-filtering (between, RTL)
hist(data.controlled.hits.between.by_rtl$rtl, xlab="RT (log10)")
ggplot(data.controlled.hits.between.by_rtl, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = .003)
ggqqplot(data.controlled.hits.between.by_rtl$rtl)

# create plots to check for outliers post-filtering (within, RTL)
hist(data.controlled.hits.within.by_rtl$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits.within, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwiddth = .003)
ggqqplot(data.controlled.hits.within.by_rtl$rtl)

# create plots to check for outliers post-filtering (both, RTL)
hist(data.controlled.hits.both.by_rtl$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits.both.by_rtl, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = .003)
ggqqplot(data.controlled.hits.both$rtl)

# check normality for RT (ms)
data.controlled.hits.ad <- ad.test(data.controlled.hits$rt) # anderson-darling pre-filter
data.controlled.hits.between.ad <- ad.test(data.controlled.hits.between$rt) # anderson-darling post-filter (between)
data.controlled.hits.within.ad <- ad.test(data.controlled.hits.within$rt) # anderson-darling post-filter (within)
data.controlled.hits.both.ad <- ad.test(data.controlled.hits.both$rt) # anderson-darling post-filter (both)
data.controlled.hits.by_rtl.ad <- ad.test(data.controlled.hits$rtl) # anderson-darling pre-filter (RTL)
data.controlled.hits.between.by_rtl.ad <- ad.test(data.controlled.hits.between.by_rtl$rtl); # anderson-darling post-filter (between, RTL)
data.controlled.hits.within.by_rtl.ad <- ad.test(data.controlled.hits.within.by_rtl$rtl); # anderson-darling post-filter (within, RTL)
data.controlled.hits.both.by_rtl.ad <- ad.test(data.controlled.hits.both.by_rtl$rtl); # anderson-darling post-filter (both, RTL)

data.controlled.hits.ad
data.controlled.hits.between.ad
data.controlled.hits.within.ad
data.controlled.hits.both.ad
data.controlled.hits.by_rtl.ad
data.controlled.hits.between.by_rtl.ad
data.controlled.hits.within.by_rtl.ad
data.controlled.hits.both.by_rtl.ad

# create plots to check for outliers pre-filtering (log)
hist(data.controlled.hits$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = .0065)
ggqqplot(data.controlled.hits$rtl)

# create plots to check for outliers post-filtering (between, log)
hist(data.controlled.hits.between$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits.between, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.between$rtl)

# create plots to check for outliers post-filtering (within, log)
hist(data.controlled.hits.within$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits.within, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.within$rtl)

# create plots to check for outliers post-filtering (both, log)
hist(data.controlled.hits.both$rtl, xlab = "RT (log10)")
ggplot(data.controlled.hits.both, aes(x = rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)
ggqqplot(data.controlled.hits.both$rtl)

# check normality for RT (log)
data.controlled.hits.ad2 <- ad.test(data.controlled.hits$rtl) # anderson-darling pre-filter (log)
data.controlled.hits.between.ad2 <- ad.test(data.controlled.hits.between$rtl) # anderson-darling post-filter (between, log)
data.controlled.hits.within.ad2 <- ad.test(data.controlled.hits.within$rtl) # anderson-darling post-filter (between, log)
data.controlled.hits.both.ad2 <- ad.test(data.controlled.hits.both$rtl) # anderson-darling post-filter (both, log)

data.controlled.hits.ad2
data.controlled.hits.between.ad2
data.controlled.hits.within.ad2
data.controlled.hits.both.ad2

# quick comment here:
# it seems quite likely to me that
# the best way to go about this will
# be to simply use the log(RT) without
# strong control over SD in RTs because
# we _will_ be working with ex-gaussians
# in the RTs anyway so the SD approach is
# a bit tedious imho and would right shift
# the distribution of our data by a lot
# anyways, make a choice here about what
# data to use, based on the plots and info
# obtained so far
# this is kind of problematic because i
# would also expect that, even in the
# best case scenario, these will not be
# perfectly normal...so where does that
# leave us exactly?
# i guess this is kind of the curse of
# working with RT data

data.chosen <- data.controlled.hits.within; # select a data set to work with
data.chosen$outcome <- data.chosen$rtl; # select an outcome variable to work with

data.chosen.loss <- (1 - (NROW(data.chosen) / NROW(data))) * 100; # how much data was removed from this data set? in per cent
data.chosen.loss

### 4: analyses

# quick comment here:
# so i have given this some thought
# and it would seem to me like to be
# perfectly honest it doesn't really
# make much sense for us to use an
# aov approach here. ideally, we want
# to get at within-subjects differences
# here and a) that means we'd already
# lose the advantages of aov because
# the comparisons we want don't come
# that naturally and b) we'd have to
# go for rmaov which is just...not
# ideal (and _almost_ lme anyway except
# worse). so we'll just build a lme
# model here. what _is_ nice is that
# our model is incredibly simple.
#
# quick comment here:
# can we think of a good reason
# not to use lme to build a cell
# means model? that really seems
# like the best approach here
#
# quick comment here:
# one thing I am not sure about is
# should we also fit nuisance reg-
# ressors for presented location?
# this might be a significant
# contributor of noise, since our
# data come from a 4AFC

# models without fixed time or display regressors, varying random effects
res.model.untimed.r1 <- lmer(outcome ~ -1 + list:pool + (1|ppn), data = data.chosen);
res.model.untimed.r2a <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id), data = data.chosen);
res.model.untimed.r2b <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|spkr), data = data.chosen);
res.model.untimed.r3 <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr), data = data.chosen);
res.model.untimed.r4a <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id), data = data.chosen);
res.model.untimed.r4b <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr), data = data.chosen);
res.model.untimed.r4c <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:spkr), data = data.chosen);
res.model.untimed.r4d <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr), data = data.chosen);
res.model.untimed.r4e <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|ppn:spkr), data = data.chosen);
res.model.untimed.r4f <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);
res.model.untimed.r4g <- lmer(outcome ~ -1 + list:pool + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);

# models without fixed time regressor, with display regressor and varying random effects
res.model.display.r1 <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn), data = data.chosen);
res.model.display.r2a <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id), data = data.chosen);
res.model.display.r2b <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|spkr), data = data.chosen);
res.model.display.r3 <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr), data = data.chosen);
res.model.display.r4a <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id), data = data.chosen);
res.model.display.r4b <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr), data = data.chosen);
res.model.display.r4c <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:spkr), data = data.chosen);
res.model.display.r4d <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr), data = data.chosen);
res.model.display.r4e <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|ppn:spkr), data = data.chosen);
res.model.display.r4f <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);
res.model.display.r4g <- lmer(outcome ~ -1 + list:pool + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);

# models with fixed time regressor, varying random effects
res.model.timed.r1 <- lmer(outcome ~ -1 + list:pool + i + (1|ppn), data = data.chosen);
res.model.timed.r2a <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id), data = data.chosen);
res.model.timed.r2b <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|spkr), data = data.chosen);
res.model.timed.r3 <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr), data = data.chosen);
res.model.timed.r4a <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id), data = data.chosen);
res.model.timed.r4b <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr), data = data.chosen);
res.model.timed.r4c <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:spkr), data = data.chosen);
res.model.timed.r4d <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr), data = data.chosen);
res.model.timed.r4e <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|ppn:spkr), data = data.chosen);
res.model.timed.r4f <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);
res.model.timed.r4g <- lmer(outcome ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);

# models with fixed time regressor, display regressor and varying random effects
res.model.both.r1 <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn), data = data.chosen);
res.model.both.r2a <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id), data = data.chosen);
res.model.both.r2b <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|spkr), data = data.chosen);
res.model.both.r3 <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr), data = data.chosen);
res.model.both.r4a <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id), data = data.chosen);
res.model.both.r4b <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr), data = data.chosen);
res.model.both.r4c <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:spkr), data = data.chosen);
res.model.both.r4d <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr), data = data.chosen);
res.model.both.r4e <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|ppn:spkr), data = data.chosen);
res.model.both.r4f <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);
res.model.both.r4g <- lmer(outcome ~ -1 + list:pool + i + (1|od) + (1|ppn) + (1|id) + (1|spkr) + (1|ppn:id) + (1|id:spkr) + (1|ppn:spkr), data = data.chosen);
res.model.both.t <- lmer(rt ~ -1 + list:pool + i + (1|ppn) + (1|id) + (1|spkr) + (1|od) + (1|ppn:id) + (1|id:spkr), data = data.controlled);

# quick comment here:
# we could also go for something
# like a 0+spkr|ppn term here but
# that's just going to give us a
# singular fit so definitely not
# ideal (but worth a try with 
# the real data).

K.none <- rbind(
  #     contrast matrix
  # VERIDICAL < STATISTICAL (WORD)
  VERIDICAL_STATWORDl = c(1, 0, 0,   # + L1P1
                          0, 0, 0,
                          -1, 0, 0), # - L1P3
  VERIDICAL_STATWORDh = c(0, 0, 0,
                          0, 1, 0,   # + L2P2
                          0, -1, 0), # - L2P3
  
  # VERIDICAL < STATISTICAL (SPKR)
  VERIDICAL_STATSPKRl = c(0, 0, 0,
                          0, 1, -1, # + L2P2 - L3P2
                          0, 0, 0),
  VERIDICAL_STATSPKRh = c(1, 0, -1, # + L1P1 - L3P1
                          0, 0, 0,
                          0, 0, 0),
  
  # STATISTICAL (WORD) < CONTROL
  STATWORDl_CONTROL = c(0, 0, 0,
                        0, 0, 0,
                        1, 0, -1), # L1P3 - L3P3
  STATWORDh_CONTROL = c(0, 0, 0,
                        0, 0, 0,
                        0, 1, -1), # L2P3 - L3P3
  
  # STATISTICAL (WORD, high) < STATISTICAL (WORD, low)
  STATWORDh_STATWORDl = c(0, 0, 0,
                          0, 0, 0,
                          -1, 1, 0), # - L1P3 + L2P3
  
  # STATISTICAL (SPKR) < CONTROL
  STATSPKRl_CONTROL = c(0, 0, 0,
                        0, 0, 1,  # + L3P2
                        0, 0, -1), # - L3P3
  STATSPKRh_CONTROL = c(0, 0, 1,  # + L3P1
                        0, 0, 0,
                        0, 0, -1), # - L3P3
  
  # STATISTICAL (SPKR, high) < STATISTICAL (SPKR, low)
  STATSPKRh_STATSPKRl = c(0, 0, 1,  # + L3P1
                          0, 0, -1, # - L3P2
                          0, 0, 0),
  
  # STATISTICAL (double) < CONTROL
  STATDOUBL2_CONTROL = c(0, 1, 0,   # + L2P1
                         0, 0, 0,
                         0, 0, -1), # - L3P3
  STATDOUBL1_CONTROL = c(0, 0, 0,
                         1, 0, 0,  # + L1P2
                         0, 0, -1) # - L3P3
);

K.pooled <- rbind(
  #     contrast matrix (poooled)
  # VERIDICAL < STATISTICAL (WORD)
  VERIDICAL_STATWORD = c(.5, 0, 0,    # + L1P1 / 2
                         0, .5, 0,    # + L2P2 / 2
                         -.5, -.5, 0), # - L1P3/2 - L2P3/2
  
  # STATISTICAL (WORD) < CONTROL
  STATWORD_CONTROL = c(0, 0, 0,
                       0, 0, 0,
                       .5, .5, -1), # (L1P3 + L2P3) / 2 - L3P3
  
  # STATISTICAL (WORD, high) < STATISTICAL (WORD, low)
  STATWORDh_STATWORDl = c(0, 0, 0,
                          0, 0, 0,
                          -1, 1, 0), # - L1P3 + L2P3
  
  # STATISTICAL (SPKR) < CONTROL
  STATSPKR_CONTROL = c(0, 0, .5,  # + L3P1 / 2
                       0, 0, .5,  # + L3P2 / 2
                       0, 0, -1), # - L3P3
  
  # STATISTICAL (SPKR, high) < STATISTICAL (SPKR, low)
  STATSPKRh_STATSPKRl = c(0, 0, 1,  # + L3P1
                          0, 0, -1, # - L3P2
                          0, 0, 0),
  
  # STATISTICAL (double) < CONTROL
  STATDOUB_CONTROL = c(0, .5, 0, # + L2P1 / 2
                       .5, 0, 0, # + L1P2 / 2
                       0, 0, -1) # - L3P3
);

K.none.long <- rbind(
  #     contrast matrix
  # VERIDICAL < STATISTICAL (WORD)
  VERIDICAL_STATWORDl = c(0,
                          1, 0, 0,   # + L1P1
                          0, 0, 0,
                          -1, 0, 0), # - L1P3
  VERIDICAL_STATWORDh = c(0,
                          0, 0, 0,
                          0, 1, 0,   # + L2P2
                          0, -1, 0), # - L2P3
  
  # STATISTICAL (WORD) < CONTROL
  STATWORDl_CONTROL = c(0,
                        0, 0, 0,
                        0, 0, 0,
                        1, 0, -1), # L1P3 - L3P3
  STATWORDh_CONTROL = c(0,
                        0, 0, 0,
                        0, 0, 0,
                        0, 1, -1), # L2P3 - L3P3
  
  # STATISTICAL (WORD, high) < STATISTICAL (WORD, low)
  STATWORDh_STATWORDl = c(0,
                          0, 0, 0,
                          0, 0, 0,
                          -1, 1, 0), # - L1P3 + L2P3
  
  # STATISTICAL (SPKR) < CONTROL
  STATSPKRl_CONTROL = c(0,
                        0, 0, 0,
                        0, 0, 1,  # + L3P2
                        0, 0, -1), # - L3P3
  STATSPKRh_CONTROL = c(0,
                        0, 0, 1,  # + L3P1
                        0, 0, 0,
                        0, 0, -1), # - L3P3
  
  # STATISTICAL (SPKR, high) < STATISTICAL (SPKR, low)
  STATSPKRh_STATSPKRl = c(0,
                          0, 0, 1,  # + L3P1
                          0, 0, -1, # - L3P2
                          0, 0, 0),
  
  # STATISTICAL (double) < CONTROL
  STATDOUBL2_CONTROL = c(0,
                         0, 1, 0,   # + L2P1
                         0, 0, 0,
                         0, 0, -1), # - L3P3
  STATDOUBL1_CONTROL = c(0,
                         0, 0, 0,
                         1, 0, 0,  # + L1P2
                         0, 0, -1) # - L3P3
);

K.pooled.long <- rbind(
  #     contrast matrix (poooled)
  # VERIDICAL < STATISTICAL (WORD)
  VERIDICAL_STATWORD = c(0,
                         .5, 0, 0,    # + L1P1 / 2
                         0, .5, 0,    # + L2P2 / 2
                         -.5, -.5, 0), # - L1P3/2 - L2P3/2
  
  # STATISTICAL (WORD) < CONTROL
  STATWORD_CONTROL = c(0,
                       0, 0, 0,
                       0, 0, 0,
                       .5, .5, -1), # (L1P3 + L2P3) / 2 - L3P3
  
  # STATISTICAL (WORD, high) < STATISTICAL (WORD, low)
  STATWORDh_STATWORDl = c(0,
                          0, 0, 0,
                          0, 0, 0,
                          -1, 1, 0), # - L1P3 + L2P3
  
  # STATISTICAL (SPKR) < CONTROL
  STATSPKR_CONTROL = c(0,
                       0, 0, .5,  # + L3P1 / 2
                       0, 0, .5,  # + L3P2 / 2
                       0, 0, -1), # - L3P3
  
  # STATISTICAL (SPKR, high) < STATISTICAL (SPKR, low)
  STATSPKRh_STATSPKRl = c(0,
                          0, 0, 1,  # + L3P1
                          0, 0, -1, # - L3P2
                          0, 0, 0),
  
  # STATISTICAL (double) < CONTROL
  STATDOUB_CONTROL = c(0,
                       0, .5, 0, # + L2P1 / 2
                       .5, 0, 0, # + L1P2 / 2
                       0, 0, -1) # - L3P3
);

# find lowest Akaike information criterion (note: refits to ML but no bother)
# alternative, could AIC() everything to avoid refit (if that were an issue)
AIC(
  res.model.untimed.r1,
  res.model.untimed.r2a,
  res.model.untimed.r2b,
  res.model.untimed.r3,
  res.model.untimed.r4a,
  res.model.untimed.r4b,
  res.model.untimed.r4c,
  res.model.untimed.r4d,
  res.model.untimed.r4e,
  res.model.untimed.r4f,
  res.model.untimed.r4g,
  res.model.display.r1,
  res.model.display.r2a,
  res.model.display.r2b,
  res.model.display.r3,
  res.model.display.r4a,
  res.model.display.r4b,
  res.model.display.r4c,
  res.model.display.r4d,
  res.model.display.r4e,
  res.model.display.r4f,
  res.model.display.r4g,
  res.model.timed.r1,
  res.model.timed.r2a,
  res.model.timed.r2b,
  res.model.timed.r3,
  res.model.timed.r4a,
  res.model.timed.r4b,
  res.model.timed.r4c,
  res.model.timed.r4d,
  res.model.timed.r4e,
  res.model.timed.r4f,
  res.model.timed.r4g,
  res.model.both.r1,
  res.model.both.r2a,
  res.model.both.r2b,
  res.model.both.r3,
  res.model.both.r4a,
  res.model.both.r4b,
  res.model.both.r4c,
  res.model.both.r4d,
  res.model.both.r4e,
  res.model.both.r4f,
  res.model.both.r4g
);

res.chosen <- res.model.display.r4f; # make a choice of best model
summary(res.chosen);
K.chosen <- K.none; # make a choice of corresponding contrast matrix

# some sanity checks
qqnorm(residuals(res.chosen)) # overall residuals
plot(res.chosen, resid(., scaled = TRUE) ~ fitted(.) | ppn, abline = 0) # residuals by participant
plot(res.chosen, resid(., scaled = TRUE) ~ fitted(.) | id, abline = 0) # residuals by speaker (mislabeled)
plot(res.chosen, resid(., scaled = TRUE) ~ fitted(.) | spkr, abline = 0) # residuals by item (mislabeled)
plot(res.chosen, resid(., scaled = TRUE) ~ fitted(.) | list, abline = 0) # residuals by list
leveneTest(residuals(res.chosen) ~ data.chosen$list);
plot(res.chosen, resid(., scaled = TRUE) ~ fitted(.) | pool, abline = 0) # residuals by pool
leveneTest(residuals(res.chosen) ~ data.chosen$pool);


# run general linear hypotheses
#
# quick note here:
# bonferroni correction is pretty
# conservative here so we should
# maybe consider using a better
# alternative here (although, it
# is, admittedly, a little bit of
# a minefield).
# consider BY or single-step?
res.chosen.glht <- summary(glht(res.chosen, K.none), test = adjusted("bonferroni"));
res.chosen.glht

### 5: visualisation
# data summaries
vis.se.mu <- setNames(aggregate(outcome~list+pool, data.chosen, mean), c("list", "pool", "se_mu"));
vis.se.sd <- setNames(aggregate(outcome~list+pool, data.chosen, sd), c("l", "p", "se_sd"));
vis.se <- setNames(cbind(vis.se.mu, vis.se.sd$se_sd), c("list", "pool", "se_mu", "se_sd"));

# terrible full visualisation using rainclouds
vis.full <- ggplot(data.chosen, aes(x = list, y = outcome, fill = pool)) + 
  geom_flat_violin(aes(fill = pool), position = position_nudge(x = .3, y = 0), adjust = 1.5, trim = FALSE, alpha = .5, colour = NA) + 
  geom_point(aes(x = list, y = outcome, colour = pool), position = position_jitter(width = .1), size = .1, shape = 20, alpha = .5) + 
  geom_boxplot(aes(x = list, y = outcome, fill = pool), outlier.shape = NA, alpha = .5, position = position_nudge(x = c(-0.05, 0, 0.05), y = 0), width = .03) +
  geom_line(data = vis.se, aes(x = list, y = se_mu, group = pool, colour = pool), linetype = 3, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  geom_point(data = vis.se, aes(x = list, y = se_mu, group = pool, colour = pool), shape = 18, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  geom_errorbar(data = vis.se, aes(x = list, y = se_mu, group = pool, colour = pool, ymin = se_mu - se_sd, ymax = se_mu + se_sd), width = .05, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  scale_colour_brewer(palette = "Dark2", name = "Pool") +
  scale_fill_brewer(palette = "Dark2", name = "Pool") + 
  xlab("List") + 
  ylab(TeX("Reaction time in $log_{10}(ms)$")) + 
  guides(color = FALSE) + 
  ggtitle("Overview of behavioural data") +
  theme(plot.title = element_text(hjust = .5))
#ggsave('/users/fabianschneider/desktop/university/master/dissertation/project/write-up/graphics_general/stash/beh/pilot_fullmodel_withincontrol_rtl.png')
vis.full

# data summaries by ppn
vis.ppn.se.mu <- setNames(aggregate(outcome~list+pool+ppn, data.chosen, mean), c("list", "pool", "ppn", "se_mu"));
vis.ppn.se.sd <- setNames(aggregate(outcome~list+pool+ppn, data.chosen, sd), c("l", "p", "ppn", "se_sd"));
vis.ppn.se <- setNames(cbind(vis.ppn.se.mu, vis.ppn.se.sd$se_sd), c("list", "pool", "ppn", "se_mu", "se_sd"));

# full visualisation by participant
vis.full.facet_ppn <- ggplot(data.chosen, aes(x = list, y = outcome, fill = pool)) + 
  geom_boxplot(aes(x = list, y = outcome, fill = pool), outlier.shape = NA, alpha = .5, position = position_nudge(x = c(-0.08, 0, 0.08), y = 0), width = .04) +
  geom_line(data = vis.ppn.se, aes(x = list, y = se_mu, group = pool, colour = pool), linetype = 3, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  geom_point(data = vis.ppn.se, aes(x = list, y = se_mu, group = ppn, colour = pool), shape = 18, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  geom_errorbar(data = vis.ppn.se, aes(x = list, y = se_mu, group = ppn, colour = pool, ymin = se_mu - se_sd, ymax = se_mu + se_sd), width = .05, position = position_nudge(x = c(.15, .15, .15, .2, .2, .2, .25, .25, .25), y = 0)) + 
  facet_wrap(vars(ppn)) + 
  scale_colour_brewer(palette = "Dark2", name = "Pool") +
  scale_fill_brewer(palette = "Dark2", name = "Pool") + 
  xlab("List") + 
  ylab(TeX("Reaction time in $log_{10}(ms)$")) + 
  guides(color = FALSE) + 
  ggtitle("Overview of behavioural data per participant") +
  theme(plot.title = element_text(hjust = .5))
#ggsave('/users/fabianschneider/desktop/university/master/dissertation/project/write-up/graphics_general/stash/beh/pilot_fullmodel-byppn_withincontrol_rtl.png')
vis.full.facet_ppn

# glht plots
#vis.contrasts.data.mu <- t(t(res.chosen@beta[-1:-2])); # two nuisance factors
#vis.contrasts.data.mu <- t(t(sqrt(diag(vcov(res.chosen)[-1:-2])))); # two nuisance factors
#vis.contrasts.data.mu <- t(t(res.chosen@beta[-1])); # one nuisance factor
#vis.contrasts.data.se <- t(t(sqrt(diag(vcov(res.chosen))[-1]))); # one nuisance factor
vis.contrasts.data.mu <- t(t(res.chosen@beta)); # no nuisance factors
vis.contrasts.data.se <- t(t(sqrt(diag(vcov(res.chosen))))); # no nuisance factors
vis.contrasts.data <- setNames(data.frame(cbind(vis.contrasts.data.mu, vis.contrasts.data.se, as.factor(vis.se$pool), as.factor(vis.se$list))), c("co_mu", "co_se", "pool", "list"));

vis.contrasts.glht1.data <- vis.contrasts.data[1:3,]; # P1L1 < P1L2 < P1L3
vis.contrasts.glht1 <- ggplot(vis.contrasts.glht1.data, aes(x = list, y = co_mu, fill = pool)) + 
  geom_errorbar(aes(ymin = co_mu - co_se, ymax = co_mu + co_se, colour = pool), width = .2) + 
  geom_point(aes(x = list, y = co_mu), size = 3, shape = c(13, 4, 1)) + 
  # sig.1
  geom_line(data = data.frame(list = c(1,2), co_mu = c(3.27, 3.27), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(1,1), co_mu = c(3.26, 3.2712), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(2,2), co_mu = c(3.26, 3.2712), pool = c(1, 1)), size = 1) + 
  annotate("text", x = 1.5, y = 3.276, label = stars.pval(res.chosen.glht$test$pvalues[[1]]), parse = FALSE) + 
  # sig.2
  geom_line(data = data.frame(list = c(2,3), co_mu = c(3.29, 3.29), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(2,2), co_mu = c(3.28, 3.2912), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(3,3), co_mu = c(3.28, 3.2912), pool = c(1, 1)), size = 1) + 
  annotate("text", x = 2.5, y = 3.35, label = stars.pval(res.chosen.glht$test$pvalues[[2]]), parse = FALSE) + 
  # sig.3
  geom_line(data = data.frame(list = c(1,3), co_mu = c(3.31, 3.31), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(1,1), co_mu = c(3.30, 3.3112), pool = c(1, 1)), size = 1) + 
  geom_line(data = data.frame(list = c(3,3), co_mu = c(3.30, 3.3112), pool = c(1, 1)), size = 1) + 
  annotate("text", x = 2, y = 3.32, label = stars.pval(res.chosen.glht$test$pvalues[[3]]), parse = FALSE) + 
  # theme
  xlab("List") + 
  ylab(TeX("Reaction time in $log_{10}(ms)$")) + 
  labs(fill = "Pool") + 
  guides(colour = FALSE) + 
  theme_bw() +
  scale_x_discrete(limits = c("1", "2", "3"))# + 
  #theme(axis.text.x = element_text(angle = 45, hjust = .5))
vis.contrasts.glht1

vis.contrasts.glht2.data <- vis.contrasts.data[4:6,]; # P2L2 < P2L1 < P2L3
vis.contrasts.glht2 <- ggplot(vis.contrasts.glht2.data, aes(x = list, y = co_mu, fill = pool)) + 
  geom_errorbar(aes(ymin = co_mu - co_se, ymax = co_mu + co_se), width = .2)

aes(x = list, y = outcome, colour = pool), position = position_jitter(width = .1), size = .1, shape = 20, alpha = .5

ggarrange(vis.contrasts.glht1, vis.contrasts.glht2)


### 6: extraction
