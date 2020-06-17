#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

levels=seq(1,10,1)
data=data.frame(Frequency = factor(levels=levels), Node=integer(), Time=double(), Name=factor(), Action=factor(), X=double(), Y=double())
for (number in levels) {
    t = read.csv(file=paste(sep='', 'results/packetLoss-', number, '.csv'), header=TRUE, sep=",")
    ## t = t[-c(5,6)]
    ## t = t[sample(1:nrow(t), 70, replace=FALSE),]
    ## ## t = t[seq(1,nrow(t),2)]
    ## names(t) = c("Time", "Delay")
    ## t$Distance = factor(distance, levels=levels)
    t$Frequency = factor(number, levels=levels)
    data = rbind(t, data)
}

s = subset(data, TotalNodes==200 & Action!="Suppressed" & Action!="Duplicate")

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
counts = adjusted %>% group_by(Action, Name, Frequency) %>% tally()

countsWithErrors = counts %>% group_by(Action, Frequency) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

    ## summarize(Time=count(Time))

g2 <- ggplot(countsWithErrors, aes(x=Frequency)) +
    geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
    geom_errorbar(aes(ymin=Min, ymax=Max, group=Action), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
    theme_custom()

## g <- ggplot(data, aes(x=Time)) +
##     xlab("Time, s") +
##     ylab("Delay, milliseconds") +
##     geom_point(aes(y=Delay, colour=Distance)) +
##     theme_custom()


ggsave("graphs/pdfs/map.pdf", plot=g, width=12, height=8, device=cairo_pdf)


ggsave("graphs/pdfs/suppressions.pdf", plot=g2, width=6, height=4, device=cairo_pdf)
