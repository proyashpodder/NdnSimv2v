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

levels = c(
    "0.5-2 m (range 1.5 m)",
    "1-2.5 m (range 1.5 m)",
    "1.5-3 m (range 1.5 m)",

    "0.5-2.5 m (range 2 m)",
    "1-3 m (range 2 m)",
    "1.5-3.5 m (range 2 m)",

    "0.5-3 m (range 2.5 m)",
    "1-3.5 m (range 2.5 m)",
    "1.5-4 m (range 2.5 m)",

    "0.5-3.5 m (range 3 m)",
    "1-4 m (range 3 m)",
    "1.5-4.5 m (range 3 m)",

    "0.5-4 m (range 3.5 m)",
    "1-4.5 m (range 3.5 m)",
    "1.5-5 m (range 3.5 m)"
)


base = read.csv(file="results/1-baseline-run-1-min-1.500000-max-3.000000.csv", header=TRUE)
data = c()
for (r in 1:nrow(ranges)) {
    for (run in 1:10) {
        tryCatch({
            mi = ranges[r, "min"]
            ma = ranges[r, "max"]

            f = file=paste(sep='', "results/2-collisions-run-", run ,"-min-", format(mi, nsmall=6),"-max-", format(ma, nsmall=6),".csv")
            d = read.csv(f, header=TRUE)
            d$Run = run
            d$Adjustment = factor(paste(sep='', mi, '-', ma, ' m (range ', ma-mi, ' m)'), levels=levels, ordered=TRUE)
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
                id.vars = c("Duration", "Run", "Adjustment"),
                measure.vars = cols,
                variable.name = "Type")


s = summarySE(dataLong, measurevar=c("value"), groupvars=c("Duration", "Adjustment", "Type"))

s1 = subset(s, (Adjustment=="1.5-3 m (range 1.5 m)" | Adjustment=="1-3 m (range 2 m)") & Duration<240)

g  <- ggplot(subset(s1, Type=="Cars that collided" | Type=="Cars that adjusted yet still collided" | Type=="Cars that adjusted"), aes(x=Duration, y=value, color=Type)) +
    geom_point() +
    geom_step() +
    geom_errorbar(aes(ymin=value-se, ymax=value+se), colour="black", width=4, size=0.2, position=position_dodge(0.2)) +
    xlab("Duration of the simulation, seconds") +
    ylab("Total number of cars in the category") +
    ## ggtitle("Dynamics for `1.5-3 m (range 1.5 m)` adjustment case") +
    theme_custom() +
    facet_wrap(~ Adjustment)

ggsave("graphs/pdfs/dynamics-1.pdf", plot=g, width=9, height=5, device=cairo_pdf)
