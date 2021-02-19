# script to run our behavioural analyses

library(tidyverse);
library(ggpubr);
library(ggplot2);
library(nortest);
library(car);

file <- "/users/fabianschneider/desktop/university/master/dissertation/project/analyses/behavioural/aggregate.txt";
afc_chance <- 1 / 4;

## 1: load data
data <- read.delim(file, header = TRUE, sep = "\t", dec=".");


## 2: control learning
hr_total <- mean(data$cor); # hit rate
hr_total_t <- t.test(data$cor, mu = afc_chance, alternative="greater"); # one-sided t-test for HR > chance
hr_participants <- aggregate(data$cor, list(data$ppn), mean); # hit rate by participant
hr_items <- aggregate(data$cor, list(data$spkr), mean); # hit rate by item
hr_speakers <- aggregate(data$cor, list(data$id), mean); # hit rate by speaker

ggplot(data = hr_participants) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr_total, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Participant") +
  ggtitle(sprintf("Learning outcomes by participant, p=%.3f.", hr_total_t$p.value)) + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggplot(data = hr_items) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr_total, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Item") +
  ggtitle("Learning outcomes by item.") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

ggplot(data = hr_speakers) + 
  geom_point(mapping = aes(x = Group.1, y = x)) +
  expand_limits(y=c(0, 1)) +
  geom_hline(yintercept=afc_chance, linetype="dashed", color="red") +
  geom_hline(yintercept=hr_total, linetype="dashed", color="black") + 
  labs(y="Hit Rate", x="Speaker") +
  ggtitle("Learning outcomes by speaker,") + 
  theme(plot.title = element_text(hjust = 0.5)) + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))


## 3: RT prep
cordata <- subset(data, cor == 1); # remove incorrect responses

hist(cordata$rt, xlab="RT (ms)")

ggplot(cordata, aes(x=rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)

cordata$rtl <- log10(cordata$rt);

hist(cordata$rtl, xlab="RT (log10(ms))")

ggplot(cordata, aes(x=rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = 1)

ggqqplot(cordata$rt)
ggqqplot(cordata$rtl)

normality_rt <- ad.test(cordata$rt) # anderson-darling on raw RT data
normality_rtl <- ad.test(cordata$rtl) # anderson-darling on log10(RT) data
# ^ this is a problem because, almost certainly, these will seem normal
# because AD is biased towards normality for bigger Ns, although the same
# problem would apply to shapiro-wilk (which we won't be able to use here
# anyways due to N>5000). Visual inspection + tests will have to do to
# make decisions here. since we are working within-participants, however,
# i think an affordance here would be to simply use a 2SD approach for
# within-participant outliers, as seen below. since this will almost 
# certainly be an exgaussian, we should do this on RTL data, not raw RTs.

mu_rt <- mean(cordata$rt);
mu_rtl <- mean(cordata$rtl);
sd_rt <- sd(cordata$rt);
sd_rtl <- sd(cordata$rtl);
# ^ mean and standard deviations across data set

mu_participant_rt <- setNames(aggregate(cordata$rt, list(cordata$ppn), mean), c("ppn", "rt_mu"));
mu_participant_rtl <- setNames(aggregate(cordata$rtl, list(cordata$ppn), mean), c("ppn", "rtl_mu"));
sd_participant_rt <- setNames(aggregate(cordata$rt, list(cordata$ppn), sd), c("ppn", "rt_sd"));
sd_participant_rtl <- setNames(aggregate(cordata$rtl, list(cordata$ppn), sd), c("ppn", "rtl_sd"));

cordata <- merge(cordata, mu_participant_rt, by="ppn");
cordata <- merge(cordata, mu_participant_rtl, by="ppn");
cordata <- merge(cordata, sd_participant_rt, by="ppn");
cordata <- merge(cordata, sd_participant_rtl, by="ppn");
# ^ mean and standard deviations within participants in data set

data_clean_rt_total <- subset(cordata, rt < (mu_rt + (2 * sd_rt)) & 
                                       rt > (mu_rt - (2 * sd_rt)));
data_clean_rtl_total <- subset(cordata, rtl < (mu_rtl + (2 * sd_rtl)) & 
                                        rtl > (mu_rtl - (2 * sd_rtl)));
# ^ outliers removed by overall data

data_clean_rt_participant <- subset(cordata, rt < (rt_mu + (2 * rt_sd)) & 
                                             rt > (rt_mu - (2 * rt_sd)));
data_clean_rtl_participant <- subset(cordata, rtl < (rtl_mu + (2 * rtl_sd)) &
                                              rtl > (rtl_mu - (2 * rtl_sd)));
# ^ outliers removed by participant data

data_clean_rt <- data_clean_rt_total; # choice of which cleaning method to use
data_clean_rtl <- data_clean_rtl_total; # choice of which cleaning method to use

data_removed_rt <- (1 - (NROW(data_clean_rt) / NROW(data))) * 100; # data removed in per cent (corr & outliers)
data_removed_rtl <- (1 - (NROW(data_clean_rtl) / NROW(data))) * 100; # data removed in per cent (corr & outliers)

hist(data_clean_rt$rt, xlab="Cleaned RT (ms)")

ggplot(data_clean_rt, aes(x=rt)) + 
  geom_dotplot(stackdir = 'center', binwidth = 15)

hist(data_clean_rtl$rtl, xlab="Cleaned RT (log10(ms))")

ggplot(data_clean_rtl, aes(x=rtl)) + 
  geom_dotplot(stackdir = 'center', binwidth = 1)

# to make an informed decision, let's neatly plot
# all qqplots again with titles such that we can evalute
# properly at this point. v
ggqqplot(data_clean_rt$rt, title="qqplot RTs of RT-cleaned data") + 
  theme(plot.title = element_text(hjust = 0.5))
ggqqplot(data_clean_rtl$rtl, title="qqplot RTLs of RTL-cleaned data") + 
  theme(plot.title = element_text(hjust = 0.5))
ggqqplot(data_clean_rt$rtl, title="qqplot RTLs of RT-cleaned data") + 
  theme(plot.title = element_text(hjust = 0.5))
ggqqplot(data_clean_rtl$rt, title="qqplot RT of RTL-cleaned data") + 
  theme(plot.title = element_text(hjust = 0.5))
# ^ note that QQplots aren't everything here because of course
# this is going to give us a log-ish plot for the RTLs - also mind
# normality (but with a grain of salt, again) and hist plots
# as a general rule of thumb, it's probably best to go with RT-
# cleaned RTL data for further analyses

normality_clean_rt <- ad.test(data_clean_rt$rt) # anderson-darling on cleaned RT data (ms)
normality_clean_rt_rtl <- ad.test(data_clean_rt$rtl) # anderson-darling on cleaned RT data (log10)
normality_clean_rtl <- ad.test(data_clean_rtl$rtl) # anderson-darling on cleaned RTL data (log10)
normality_clean_rt <- ad.test(data_clean_rtl$rt) # anderson-darling on cleaned RTL data (ms)
# ^ note that, upon making a decision, the data used in the next section
# should be changed accordingly (i.e., we reassign to a new variable to
# make it easier to change decisions at this stage)


## 4: RT analyses
cleaned_data <- data_clean_rt; # selection of which data to run analyses with
cleaned_data$outcome <- cleaned_data$rt; # selection of which outcome to work with
outcome_label <- "RT (ms)";
cleaned_data$list <- factor(cleaned_data$list);
cleaned_data$pool <- factor(cleaned_data$pool);

res.hete <- leveneTest(outcome ~ pool * list, data = cleaned_data);
res.aov2 <- aov(outcome ~ pool * list, data = cleaned_data);
summary(res.aov2)
res.spkr <- TukeyHSD(res.aov2, which = "pool");
res.item <- TukeyHSD(res.aov2, which = "list");

res.mu <- setNames(aggregate(cleaned_data$outcome, by=list(cleaned_data$list, cleaned_data$pool), mean), c("list", "pool", "outcome"));
res.sd <- setNames(aggregate(cleaned_data$outcome, by=list(cleaned_data$list, cleaned_data$pool), sd), c("list", "pool", "sd"));
res.sum <- res.mu;
res.sum$sd <- res.sd$sd;


# violin plots
#ggplot(cleaned_data, aes(x = list, y = outcome, fill = pool)) + 
#  geom_violin(position = position_dodge(1)) + 
#  geom_point(position = position_dodge(1), size = 1) + 
#  facet_grid(list ~ pool)
#  geom_dotplot(binaxis = 'y', bins=1, stackdir = 'center', position = position_dodge(1))
#  geom_boxplot(width = 0.1, fill = "white")

# box plots
#compare_means(outcome ~ list * pool, data = cleaned_data, method="anova");
#ggboxplot(cleaned_data, x = "list", y = "outcome", color = "pool", palette = "jco", add = "jitter", short.panel.labs = FALSE) + 
#  stat_compare_means(aes(group = pool), label = "p.signif", paired = FALSE, hide.ns = FALSE)

# summary interaction plots
ggplot(res.sum, aes(x = list, y = outcome, group = pool, color = pool)) + 
  geom_line(position = position_dodge(.25), linetype = "dashed") + 
  geom_point(position = position_dodge(.25), size = 2) + 
  geom_errorbar(aes(ymin = outcome - sd, ymax = outcome + sd), width = .2, position = position_dodge(.25)) + 
  labs(title = "Two-way interaction plots of model", x = "List", y = outcome_label, color = "Pool") + 
  theme(plot.title = element_text(hjust = 0.5))

# bar plots
#ggplot(res.sum, aes(x = list, y = outcome, fill = pool)) + 
#  geom_bar(stat = "identity", color = "black", position = position_dodge()) + 
#  geom_errorbar(aes(ymin = outcome - sd, ymax = outcome + sd), width = .2, position = position_dodge(.9)) + 
#  labs(title  ="Two-way interaction plots of model", x = "List", y = "RT (ms)")