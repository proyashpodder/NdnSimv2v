#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

tmin=c("0.050000")
## tmin=c("0.020000")
data=data.frame(Node=integer(), Time=double(), Name=factor(), Action=factor(), X=double(), Y=double(), Tmin=factor(levels=tmin))
for (time in tmin) {
    t = read.csv(file=paste(sep='', 'results/srcinmiddle-100-tmin=', time ,'-tmax=0.300000.csv'), header=TRUE, sep=",")
    ## t = t[-c(5,6)]
    t$Tmin = factor(time, levels=tmin)
    data = rbind(t, data)
}

s = subset(data, Name < 5 & Action!="Suppressed" & Action!="Duplicate")

g <- ggplot(s, aes(x=X, y=Y)) +
    theme_custom() +
    geom_point(aes(colour=Action, size=Action)) +
    scale_size_manual(values=c(4,1)) +
    facet_grid(Name ~ .)

## adjusted = subset(data, Action != "Duplicate")
## ## levels(adjusted$Action) = c("Broadcast", "Received", "Received", "Suppressed")

## ## p.Wages.all.A_MEAN <- Wages.all %>%
## ##                   group_by(`Career Cluster`, Year)%>%
## ##                   summarize(ANNUAL.MEAN.WAGE = mean(A_MEAN))
## counts = adjusted %>% group_by(Action, Name, Tmin) %>% tally()

## countsWithErrors = counts %>% group_by(Action, Tmin) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

##     ## summarize(Time=count(Time))

## g2 <- ggplot(countsWithErrors, aes(x=Tmin)) +
##     geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
##     geom_errorbar(aes(ymin=Min, ymax=Max, group=Action), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
##     theme_custom()

## ## g <- ggplot(data, aes(x=Time)) +
## ##     xlab("Time, s") +
## ##     ylab("Delay, milliseconds") +
## ##     geom_point(aes(y=Delay, colour=Distance)) +
## ##     theme_custom()


ggsave("graphs/pdfs/srcinmiddle-map.pdf", plot=g, width=8, height=5, device=cairo_pdf)


## ggsave("graphs/pdfs/srcinmiddle-bars.pdf", plot=g2, width=6, height=4, device=cairo_pdf)
