#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

levels=seq(1,20,1)
data=data.frame(Frequency = factor(levels=levels), Node=integer(), Time=double(), Name=factor(), Action=factor(), X=double(), Y=double())
for (number in levels) {
    t = read.csv(file=paste(sep='', 'results/nConsumer-packetLoss-', number, '.csv'), header=TRUE, sep=",")
    ## t = t[-c(5,6)]
    ## t = t[sample(1:nrow(t), 70, replace=FALSE),]
    ## ## t = t[seq(1,nrow(t),2)]
    ## names(t) = c("Time", "Delay")
    ## t$Distance = factor(distance, levels=levels)
    t$Consumer = factor(number, levels=levels)
    data = rbind(t, data)
}

adjusted = subset(data, Action != "Duplicate" & Action != "Suppressed")
## levels(adjusted$Action) = c("Broadcast", "Received", "Received", "Suppressed")

## p.Wages.all.A_MEAN <- Wages.all %>%
##                   group_by(`Career Cluster`, Year)%>%
##                   summarize(ANNUAL.MEAN.WAGE = mean(A_MEAN))
counts = adjusted %>% group_by(Action, Name, Consumer) %>% tally()

countsWithErrors = counts %>% group_by(Action, Consumer) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

    ## summarize(Time=count(Time))

g2 <- ggplot(countsWithErrors, aes(x=Consumer)) +
    geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
    theme_custom()

## g <- ggplot(data, aes(x=Time)) +
##     xlab("Time, s") +
##     ylab("Delay, milliseconds") +
##     geom_point(aes(y=Delay, colour=Distance)) +
##     theme_custom()


#ggsave("graphs/pdfs/map.pdf", plot=g, width=12, height=8, device=cairo_pdf)


ggsave("graphs/pdfs/suppressions.pdf", plot=g2, width=6, height=4, device=cairo_pdf)
