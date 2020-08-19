#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(reshape2))

source("graphs/graph-style.R")
source("graphs/helpers.R")


ranges = data.frame(min=double(), max=double())
minList = c(0.5, 1, 1.5)
rangeList = c(1.5, 2, 2.5, 3, 3.5)
for (m in minList) {
    for (r in rangeList) {
        ranges = ranges %>% add_row(min=m, max=m+r)
    }
}

base = read.csv(file="results/1-baseline-run-1-min-1.500000-max-3.000000.csv", header=TRUE)
data = c()
for (r in 1:nrow(ranges)) {
    for (run in 1:11) {
        tryCatch({
            mi = ranges[r, "min"]
            ma = ranges[r, "max"]
        d = read.csv(file=paste(sep='', "results/2-collisions-run-", run ,"-min-", format(mi, nsmall=6),"-max-", format(ma, nsmall=6),".csv"), header=TRUE)
        d$Run = run
        d$MinAdjustment = factor(mi)
        d$MaxAdjustment = factor(ma)
        d
        if (length(data) == 0) {
            data = d
        } else {
            data = rbind(d, data)
        }
        }, warning = function(w) {
            print(w)
        }, error = function(e) {
            print(e)
        }, finally = {
        })
    }
}

colsOrig = c("Total_Number_Of_Vehicle", "Total_Adjusted_Car", "Total_Collided_Car", "totalCollidedNotAdjustedCar", "totalAdjustedButCollidedCar")
cols = c("All vehicles", "Cars that adjusted", "Cars that collided", "Cars that did not adjust and collided", "Cars that adjusted yet still collided")

for (i in 1:length(colsOrig)) {
    names(data)[names(data) == colsOrig[i]] <- cols[i]
}

dataLong = melt(data,
                id.vars = c("Duration", "Run", "MinAdjustment", "MaxAdjustment"),
                measure.vars = cols,
                variable.name = "Type")


s = summarySE(dataLong, measurevar=c("value"), groupvars=c("Duration", "MinAdjustment","MaxAdjustment", "Type"))

s1 = subset(s, Duration==300)


## g <- ggplot(s, aes(x=X, y=Y)) +
##     theme_custom() +
##     geom_point(aes(colour=Action, size=Action)) +
##     scale_size_manual(values=c(4,1)) +
##     facet_grid(Name ~ .)

## adjusted = subset(data, Action != "Duplicate" & Action != "Suppressed")
## ## levels(adjusted$Action) = c("Broadcast", "Received", "Received", "Suppressed")

## ## p.Wages.all.A_MEAN <- Wages.all %>%
## ##                   group_by(`Career Cluster`, Year)%>%
## ##                   summarize(ANNUAL.MEAN.WAGE = mean(A_MEAN))
## counts = adjusted %>% group_by(Action, Name, TotalNodes) %>% tally()

## countsWithErrors = counts %>% group_by(Action, TotalNodes) %>% summarize(Mean=mean(n), Min=min(n), Max=max(n))

##     ## summarize(Time=count(Time))

## g2 <- ggplot(countsWithErrors, aes(x=TotalNodes)) +
##     geom_bar(stat="identity", aes(y=Mean, colour=Action, fill=Action), position="dodge") +
##     geom_errorbar(aes(ymin=Min, ymax=Max, group=Action), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
##     theme_custom()

## ## g <- ggplot(data, aes(x=Time)) +
## ##     xlab("Time, s") +
## ##     ylab("Delay, milliseconds") +
## ##     geom_point(aes(y=Delay, colour=Distance)) +
## ##     theme_custom()


## ggsave("graphs/pdfs/map.pdf", plot=g, width=12, height=8, device=cairo_pdf)


## ggsave("graphs/pdfs/suppressions.pdf", plot=g2, width=6, height=4, device=cairo_pdf)
