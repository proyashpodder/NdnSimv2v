#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

## tmin=c("0.010000", "0.020000", "0.030000", "0.040000", "0.050000", "0.060000", "0.070000", "0.080000", "0.090000", "0.100000")
tmin=c("0.010000")
## tmax=c("0.100000", "0.200000", "0.300000", "0.400000", "0.500000", "0.600000")
tmax=c("0.200000")
data=data.frame(Node=integer(), Time=double(), Name=factor(), Action=factor(), X=double(), Y=double(), Tmax=factor(levels=tmax))
for (time in tmax) {
    t = read.csv(file=paste(sep='', 'results/2hopsnoproducer-400-tmin=0.010000-tmax=', time ,'.csv'), header=TRUE, sep=",")
    ## t = t[-c(5,6)]
    t$Tmax = factor(time, levels=tmax)
    data = rbind(t, data)
}

s = subset(data, Name<5 & Action!="Suppressed" & Action!="Duplicate")

g <- ggplot(s, aes(x=X, y=Y)) +
    theme_custom() +
    geom_point(aes(colour=Action, size=Action)) +
    scale_size_manual(values=c(4,1)) +
    facet_grid(Name ~ .)

adjusted = subset(data, Action != "Duplicate" & Action != "Suppressed")
## levels(adjusted$Action) = c("Broadcast", "Received", "Received", "Suppressed")

## p.Wages.all.A_MEAN <- Wages.all %>%
##                   group_by(`Career Cluster`, Year)%>%
##                   summarize(ANNUAL.MEAN.WAGE = mean(A_MEAN))
counts = adjusted %>% group_by(Action, Name, Tmax) %>% tally()

countsWithErrors = counts %>% group_by(Action, Tmax) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

    ## summarize(Time=count(Time))

g2 <- ggplot(countsWithErrors, aes(x=Tmax)) +
    geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
    geom_errorbar(aes(ymin=Min, ymax=Max, group=Action), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
    theme_custom()

## g <- ggplot(data, aes(x=Time)) +
##     xlab("Time, s") +
##     ylab("Delay, milliseconds") +
##     geom_point(aes(y=Delay, colour=Distance)) +
##     theme_custom()


ggsave("graphs/pdfs/2hopnoproducer-map.pdf", plot=g, width=12, height=8, device=cairo_pdf)


ggsave("graphs/pdfs/2hopnoproducer-bars.pdf", plot=g2, width=6, height=4, device=cairo_pdf)



x = subset(data, Action=="Received") %>% group_by(Tmax, Name) %>% summarize(Min=min(Time),Max=max(Time), MaxDelay=max(Time)-min(Time))
x$Name = factor(x$Name)

y = subset(data, Action=="Received")
y$Name = factor(y$Name)

z = y %>% inner_join(x) %>% mutate(Delay = Time-Min)

## g <- ggplot(x, aes(x=Tmax)) +
##     geom_point(aes(y=MaxDelay, colour=Name)) +
##     theme_custom()

g <- ggplot(z, aes(x=X)) +
    geom_point(aes(y=Delay, colour=Name)) +
    theme_custom()


ggsave("graphs/pdfs/2hopnoproducerdelays.pdf", plot=g, width=6, height=4, device=cairo_pdf)
