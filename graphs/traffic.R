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

f = file("results/single.csv")
d = read.table(f, header=TRUE)
# data = rbind(d, data)
data = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "InInterests" | Type == "OutData" | Type == "InData"))
#data.x2 = subset(data, Type == "OutInterests" | Type == "OutData")
dat<- ddply(data, "Time", numcolwise(sum))
g<-ggplot(dat,aes(x=Time, y=KilobytesRaw)) + geom_line(size=0.6) + theme_custom()

ggsave("graphs/pdfs/total_traffic.pdf", plot=g, width=9, height=5, device=cairo_pdf)



b <- read.csv(file="results/baseline-traffic-1.csv")
b[2] <- NULL
b$Type="Baseline"

f = file("results/multiple-numbers-0-rates-run-1.csv")
m = read.table(f,header=TRUE)
m = subset(m, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
m[2:8] <- NULL
m <- ddply(m, "Time", numcolwise(sum))
m$Type <- "MultiplePoint"

mb = rbind(b,m)


g = file("results/one-numbers-0-rates-run-1.csv")
t = read.table(g,header=TRUE)
t = subset(t, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
t[2:8] <- NULL
t <- ddply(t, "Time", numcolwise(sum))
t$Type <- "TrajectoryPoint"

mbt = rbind(mb,t)

g <- ggplot(mbt,aes(x=Time,y=KilobytesRaw, color=Type)) + geom_line(size=0.6)+theme_custom()
ggsave("graphs/pdfs/all-3-200ped.pdf", plot=g, width=9, height=5, device=cairo_pdf)



b <- read.csv(file="results/baseline-traffic-1.csv")
b$Type="Baseline"

f = file("results/multiple-numbers-0-rates-run-1.csv")
m = read.table(f,header=TRUE)
m = subset(m, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
m[2:7] <- NULL
m <- ddply(m, "Time", numcolwise(sum))
m$Type <- "MultiplePoint"

mb = rbind(b,m)


g = file("results/one-numbers-0-rates-run-1.csv")
t = read.table(g,header=TRUE)
t = subset(t, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
t[2:7] <- NULL
t <- ddply(t, "Time", numcolwise(sum))
t$Type <- "TrajectoryPoint"

mbt = rbind(mb,t)

g <- ggplot(mbt,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom()
ggsave("graphs/pdfs/packet-all-3-200ped.pdf", plot=g, width=9, height=5, device=cairo_pdf)



g = file("results/multiple-numbers-0-rates-run-1.csv")
dat = read.table(g,header=TRUE)
i = subset(dat, FaceDescr=="lte://" & (Type == "OutInterests"))
d = subset(dat, FaceDescr=="lte://" & (Type == "OutData"))
i <- ddply(i, "Time", numcolwise(sum))
d <- ddply(d, "Time", numcolwise(sum))
i$Type= "Interest"
d$Type = "Data"
d =rbind(d,i)
g <- ggplot(d,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom()
ggsave("graphs/pdfs/DataVsInterest-multiple-ped200.pdf", plot=g, width=9, height=5, device=cairo_pdf)

