# script to run our behavioural analyses

library(tidyverse);

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


## 3: RT analysis
