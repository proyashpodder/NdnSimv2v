#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(reshape2))

# install.packages('doBy')
suppressPackageStartupMessages(library(doBy))

source("graphs/graph-style.R")
source("graphs/helpers.R")


ranges = data.frame(min=c(1.5, 1), max=c(3, 3))
## minList = c(0.5, 1, 1.5)
## rangeList = c(1.5, 2, 2.5, 3, 3.5)
## for (m in minList) {
##     for (r in rangeList) {
##         ranges = ranges %>% add_row(min=m, max=m+r)
##     }
## }

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


data = c()
for (r in 1:nrow(ranges)) {
    for (run in 1:10) {
        tryCatch({
            mi = ranges[r, "min"]
            ma = ranges[r, "max"]

            f = file(paste(sep='', "results/3-rates-app-delays-run-", run ,"-min-", format(mi, nsmall=6),"-max-", format(ma, nsmall=6),".csv"))
            d = read.table(f, header=TRUE)
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

data$Type = factor(data$Type)
data$Node = factor(data$Node)
data$HopCount = factor(data$HopCount)

g1  <- ggplot(data, aes(x = DelayS, fill=HopCount, color=HopCount)) +
    geom_histogram(aes(y=..density..), position="identity", alpha=0.5) +
    geom_density(alpha=0.8, color="black", size=0.2) +
    ylab("Number of samples / Probability Density Function") +
    xlab("Data retrieval delay, seconds") +
    theme_custom()

g2  <- g1 + facet_wrap(~ Adjustment)

g3  <- g1 + facet_grid(Adjustment ~ Run)

ggsave("graphs/pdfs/5-delays-combined.pdf", plot=g1, width=9, height=5, device=cairo_pdf)
ggsave("graphs/pdfs/5-delays-per-adjustment.pdf", plot=g2, width=9, height=5, device=cairo_pdf)
ggsave("graphs/pdfs/5-delays-individual.pdf", plot=g3, width=9, height=5, device=cairo_pdf)


## # combine stats from all faces
## data.combined = summaryBy(. ~ Run + Adjustment + Time + Type, data=data, FUN=sum)

## data.s = summarySE(data.combined, measurevar=c("Packets.sum"), groupvars=c("Adjustment", "Time", "Type"))

## data.x = subset(data.s, Type == "OutInterests" | Type == "OutData")

## g <- ggplot(data.x, aes(x=Time, y=Packets.sum, color=Type)) +
##     geom_point(size=1) +
##     geom_line(size=0.2) +
##     geom_errorbar(aes(ymin=Packets.sum-se, ymax=Packets.sum+se), width=4, size=0.2, position=position_dodge(0.2)) +
##     ylab("Number of (interest/data) packets per second") +
##     theme_custom() +
##     facet_wrap(~ Adjustment)

## ggsave("graphs/pdfs/rates-1-packets.pdf", plot=g, width=9, height=5, device=cairo_pdf)


## data.s2 = summarySE(data.combined, measurevar=c("Kilobits.sum"), groupvars=c("Adjustment", "Time", "Type"))

## data.x2 = subset(data.s2, Type == "OutInterests" | Type == "OutData")

## g <- ggplot(data.x2, aes(x=Time, y=Kilobits.sum, color=Type)) +
##     geom_point(size=1) +
##     geom_line(size=0.2) +
##     geom_errorbar(aes(ymin=Kilobits.sum-se, ymax=Kilobits.sum+se), width=4, size=0.2, position=position_dodge(0.2)) +
##     ylab("Data rate for (interest/data) packets") +
##     theme_custom() +
##     facet_wrap(~ Adjustment)

## ggsave("graphs/pdfs/rates-2-kilobits.pdf", plot=g, width=9, height=5, device=cairo_pdf)



## data.s3 = summarySE(data, measurevar=c("Kilobits"), groupvars=c("Node", "Adjustment", "Time", "Type"))
## data.s3 = subset(data.s3, Adjustment == "1.5-3 m (range 1.5 m)")
## data.x3 = subset(data.s3, Type == "OutInterests" | Type == "OutData")


## g <- ggplot(data.x3, aes(x=Time, y=Kilobits, color=Type)) +
##     geom_line(size=0.6) +
##     ylab("Data rate for (interest/data) packets") +
##     theme_custom() +
##     facet_wrap(~ Node)

##     ## geom_point(size=1) +

## ggsave("graphs/pdfs/rates-3-kilobits-per-node.pdf", plot=g, width=9, height=5, device=cairo_pdf)

## ## geom_errorbar(aes(ymin=Kilobits.sum-se, ymax=Kilobits.sum+se), width=4, size=0.2, position=position_dodge(0.2)) +
