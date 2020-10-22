#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(dplyr))
suppressPackageStartupMessages(library(plyr))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(reshape2))
suppressPackageStartupMessages(library(ddply))

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



h = file("results/one-numbers-0-rates-run-1-w-o-s.csv")
q = read.table(h,header=TRUE)
q = subset(q, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
q[2:7] <- NULL
q <- ddply(q, "Time", numcolwise(sum))
q$Type <- "Without_Strategy"

g = file("results/one-numbers-0-rates-run-1-w-s.csv")
t = read.table(g,header=TRUE)
t = subset(t, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
t[2:7] <- NULL
t <- ddply(t, "Time", numcolwise(sum))
t$Type <- "With_Strategy"

i = file("results/one-numbers-0-rates-run-1-w-m-s.csv")
p = read.table(i,header=TRUE)
p = subset(p, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
p[2:7] <- NULL
p <- ddply(p, "Time", numcolwise(sum))
p$Type <- "With_Modified_Strategy"

gh = data.frame(Time=q$Time,(q[2:3]-t[2:3])/q[2:3]*100)
# g <- ggplot(gh,aes(x=Time,y=PacketRaw)) + geom_line(size=0.6)+scale_y_continuous(limits = c(0, 100))+theme_custom()
av = summarise(gh, Average = mean(PacketRaw, na.rm = T))
g <- ggplot(size=0.6)+geom_line(data=gh, aes(x=Time,y=PacketRaw))+geom_hline(yintercept = 30, color= "red") + theme_custom() + scale_y_continuous(limits = c(0, 100))
ggsave("graphs/pdfs/withorwithoutstrategy.pdf", plot=g, width=9, height=5, device=cairo_pdf)


x = file("results/current_strategy.csv")
c = read.table(x,header=TRUE)
c = subset(c, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
c[2:7] <- NULL
c <- ddply(t, "Time", numcolwise(sum))
c$Type <- "Current_Strategy"


y = file("results/proximity.csv")
p = read.table(y,header=TRUE)
p = subset(p, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
p[2:7] <- NULL
p <- ddply(p, "Time", numcolwise(sum))
p$Type <- "Proximity"

z = file("results/proximity_1hop.csv")
h = read.table(z,header=TRUE)
h = subset(h, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
h[2:7] <- NULL
h <- ddply(h, "Time", numcolwise(sum))
h$Type <- "1Hop_Proximity"


