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


d.rates = read.table(file("results/4-rates.txt"), header=TRUE)
d.rates$Type = factor(d.rates$Type)
d.rates$FaceDescr = factor(d.rates$FaceDescr)
d.rates$Node = factor(d.rates$Node)
d.rates$FaceId = factor(d.rates$FaceId)
d.rates$Kilobits = d.rates$Kilobytes * 8

d.delays = read.table(file("results/4-delays.txt"), header=TRUE)
d.speed = read.csv(file="results/4-multiple_adjusted_speed_accel.csv", header=TRUE)



g  <- ggplot(subset(d.speed, Time<50), aes(x=Time, y=Speed)) +
    geom_point() +
    geom_line(size=0.5) +
    ylim(0, 12) +
    theme_custom()

x.rates = subset(d.rates, FaceDescr=="lte://" & Node=="f7.0" & (Type == "OutInterests" | Type == "InData"))


g <- ggplot(x.rates, aes(x=Time, y=PacketRaw, color=Type)) +
    geom_point(aes(x=Time, y=PacketRaw, color=Type, shape=Type)) +
    geom_line(aes(x=Time, y=PacketRaw, color=Type), size=0.3) +
    ylab("Number of (interest/data) packets per second") +
    xlim(0,50) +
    theme_custom()




g  <- ggplot(subset(d.speed, Time<50), aes(x=Time, y=Speed)) +
    geom_point() +
    geom_line(size=0.5) +
    xlim(0,50) +
    scale_y_continuous(
        name = "Speed, meters per second",
        limits = c(0, 12),
        sec.axis = sec_axis(~.*0.2, name = "Number of (interest/data) packets per second")
    ) +
    geom_point(data=x.rates, aes(x=Time, y=PacketRaw*5, color=Type, shape=Type)) +
    geom_line(data=x.rates, aes(x=Time, y=PacketRaw*5, color=Type), size=0.3) +
    theme_custom()

##     ## geom_point(size=1) +

ggsave("graphs/pdfs/4-one-car-position-and-rates.pdf", plot=g, width=11, height=5, device=cairo_pdf)

## ## geom_errorbar(aes(ymin=Kilobits.sum-se, ymax=Kilobits.sum+se), width=4, size=0.2, position=position_dodge(0.2)) +
