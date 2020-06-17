#!/usr/bin/env Rscript

suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

data= read.csv('results/dis-freq-packetLoss.csv')
adjusted = subset(data,frequency > 10)
g<-ggplot(data,aes(x=distance,y=percentage)) + geom_line(color="steelblue", size=1) + geom_point(color="steelblue") + facet_grid(frequency ~ .)

g2<-ggplot(adjusted,aes(x=distance,y=percentage)) + geom_line(color="steelblue", size=1) + geom_point(color="steelblue") + facet_grid(frequency ~ .)

ggsave("graphs/pdfs/dist-freq-packetLoss-3.pdf", plot=g, width=12, height=8, device=cairo_pdf)

ggsave("graphs/pdfs/dist-freq-packetLoss-10-16.pdf", plot=g2, width=12, height=8, device=cairo_pdf)
