#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

tmin=c("0.010000", "0.020000", "0.030000", "0.040000", "0.050000", "0.060000", "0.070000", "0.080000", "0.090000", "0.100000")
data=data.frame(Node=integer(), Time=double(), Name=factor(), Action=factor(), X=double(), Y=double(), Tmin=factor(levels=tmin))
for (time in tmin) {
    t = read.csv(file=paste(sep='', 'results/100-tmin=', time ,'-tmax=0.200000-cancelasunhelpful.csv'), header=TRUE, sep=",")
    ## t = t[-c(5,6)]
    t$Tmin = factor(time, levels=tmin)
    data = rbind(t, data)
}

s = subset(data, Name==2 & Action!="Received" & Action!="Duplicate")

g <- ggplot(s, aes(x=X, y=Y)) +
    theme_custom() +
    geom_point(aes(colour=Action, size=Action)) +
    scale_size_manual(values=c(4,1)) +
    facet_grid(Tmin ~ .)

adjusted = subset(data, Action != "Duplicate")
## levels(adjusted$Action) = c("Broadcast", "Received", "Received", "Suppressed")

## p.Wages.all.A_MEAN <- Wages.all %>%
##                   group_by(`Career Cluster`, Year)%>%
##                   summarize(ANNUAL.MEAN.WAGE = mean(A_MEAN))
counts = adjusted %>% group_by(Action, Name, TotalNodes) %>% tally()

countsWithErrors = counts %>% group_by(Action, TotalNodes) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

    ## summarize(Time=count(Time))

g2 <- ggplot(countsWithErrors, aes(x=TotalNodes)) +
    geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
    geom_errorbar(aes(ymin=Min, ymax=Max, group=Action), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
    theme_custom()

## g <- ggplot(data, aes(x=Time)) +
##     xlab("Time, s") +
##     ylab("Delay, milliseconds") +
##     geom_point(aes(y=Delay, colour=Distance)) +
##     theme_custom()


ggsave("graphs/pdfs/suppression-vs-timers-map.pdf", plot=g, width=12, height=8, device=cairo_pdf)


ggsave("graphs/pdfs/suppression-vs-timers-bars.pdf", plot=g2, width=6, height=4, device=cairo_pdf)
