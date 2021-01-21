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
c <- ddply(c, "Time", numcolwise(sum))
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


y = file("results/60-20-ped-12-poi-6-pro-300-consumerdistance.csv")
p = read.table(y,header=TRUE)
p = subset(p, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
p[2:7] <- NULL
data <- ddply(p, "Time", numcolwise(sum))
data$Count <- "20"


l <- c(40,80,160,320,640)
#data=data.frame(Time=integer(), PacketsRaw=double(), KilobytesRaw=factor())
for (i in l){
    #print(paste(sep='','results/new-400-ped-12-poi-',i,'-consumerdistance.csv'))
    f = file(paste(sep='', 'results/60-',i,'-ped-12-poi-6-pro-300-consumerdistance.csv'))
    d = read.table(f,header=TRUE)
    d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
    d[2:7] <- NULL
    d <- ddply(d, "Time", numcolwise(sum))
    d$Count <- i
    data = rbind(data,d)
}
data$Type= "NDN"

b <- read.csv(file="results/baseline-ped-20.csv")
b$Count="20"

o <- c(40,80,160,320,640)
for (j in o){
    g = read.csv(paste(sep='','results/baseline-ped-',j,'.csv'))
    g$Count = j
    b = rbind(b,g)
}
b$Type= "Baseline"

d = rbind(data,b)
g <- ggplot(d,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() + facet_wrap(~ Count)

y = file("results/200-ped-1-poi-100-consumerdistance.csv")
q = read.table(y,header=TRUE)
p = subset(q, FaceDescr=="lte://" & (Type == "OutInterests"))
p[2:7] <- NULL
p <- ddply(p, "Time", numcolwise(sum))
p$Type <- "Interest"

r = subset(q, FaceDescr=="lte://" & (Type == "OutData"))
r[2:7] <- NULL
r <- ddply(r, "Time", numcolwise(sum))
r$Type <- "Data"

pr = rbind(p,r)

b <- read.csv(file="results/consumerCount-distance-100.csv")
b$Type = "consumerCount"


g <- ggplot(pr,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() + scale_x_continuous(name="Time (s)", limits=c(0, 120))
ggsave("graphs/pdfs/1Poi-ped200-Data-Interest.pdf", plot=g, width=9, height=5, device=cairo_pdf)


y = file("results/ld-320-ped-12-poi-6-pro-300-consumerdistance.csv")
p = read.table(y,header=TRUE)
p = subset(p, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
p[2:7] <- NULL
data <- ddply(p, "Time", numcolwise(sum))
data$Count <- "ld"


l <- c(md,hd)
#data=data.frame(Time=integer(), PacketsRaw=double(), KilobytesRaw=factor())
for (i in l){
    #print(paste(sep='','results/new-400-ped-12-poi-',i,'-consumerdistance.csv'))
    f = file(paste(sep='', 'results-',i,'-320-ped-12-poi-6-pro-300-consumerdistance.csv'))
    d = read.table(f,header=TRUE)
    d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
    d[2:7] <- NULL
    d <- ddply(d, "Time", numcolwise(sum))
    d$Count <- i
    data = rbind(data,d)
}
data$Type= "NDN"

tMin <- c(0.02,0.08,0.12,0.16,0.2)
tMax <- c (0.2,0.25,0.3,0.35,0.4,0.45)
data = c()

for (tmin in tMin){
    for (tmax in tMax){
        f = file(paste(sep='', 'results/',tmin,'-',tmax,'-ld-40-ped-12-poi-6-pro-100-consumerdistance.csv'))
        d = read.table(f,header=TRUE)
        d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
        d[2:7] <- NULL
        d <- ddply(d, "Time", numcolwise(sum))
        d$tmin = tmin
        d$tmax = tmax
        range = paste(sep='',tmin,'-',tmax)
        d$Delayrange = range
        if(length(data) == 0){
            data =  d
            }
        else{
            data = rbind(d,data)
            }


 

    }
}

g <- ggplot(data,aes(x=Time,y=PacketRaw, color=Delayrange)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~tmin)

rn <- c(1,2,3,4,5,6,7,8,9,10)
data = c()
#data=data.frame(Time=double(), PacketRaw=double(), KilobytesRaw=double())
for (r in rn){
    f = file(paste(sep='', 'results/',r,'-0.2-0.3-ld-160-ped-12-poi-6-pro-100-consumerdistance.csv'))
    d = read.table(f,header=TRUE)
    d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
    d[2:7] <- NULL
    d <- ddply(d, "Time", numcolwise(sum))
    d$Count <- r
    #data = rbind(d,data)
    if(length(data) == 0){
        data =  d
        }
    else{
        data = rbind(d,data)
        }
        
}
g <- ggplot(data,aes(x=Time,y=PacketRaw, color=factor(Count))) + geom_line(size=0.6)+theme_custom()

detach(package:plyr)
dd <- data %>% group_by(Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))

g2 <- ggplot(dd, aes(x=Time)) +
    geom_bar(stat="identity", aes(y=Mean), position="dodge") +
      geom_errorbar(aes(ymin=Min, ymax=Max, group=Time), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
      theme_custom() + scale_y_continuous(limits=c(0,1000))

suppressPackageStartupMessages(library(plyr))
rn <- c(1,2,3,4,5,6,7,8,9,10)
data = c()
pedCount = c(40,80,160,320,640)


for (ped in pedCount){
    for (r in rn){
        f = file(paste(sep='', 'results/',r,'-0.2-0.3-ld-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
        d = read.table(f,header=TRUE)
        d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
        d[2:7] <- NULL
        d <- ddply(d, "Time", numcolwise(sum))
        d$Count <- ped
        d$Run <- r

        if(length(data) == 0){
            data =  d
            }
        else{
            data = rbind(d,data)
            }
    }
}

detach(package:plyr)
dd <- data %>% group_by(Count,Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()
g2 <- ggplot(dd, aes(x=Time)) +
    geom_bar(stat="identity", aes(y=Mean), position="dodge") +
      geom_errorbar(aes(ymin=Min, ymax=Max, group=Time), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
      theme_custom() + facet_wrap(~Count)

ggsave("graphs/pdfs/var-ped-ld-random-traffic", plot=g2, width=9, height=5, device=cairo_pdf)




suppressPackageStartupMessages(library(plyr))
rn <- c(1,2,3,4,5,6,7,8,9,10)
data = c()
pedCount = c(40,80,160,320,640)
density = c("ld","hd")

for (den in density){
    for (ped in pedCount){
        for (r in rn){
            f = file(paste(sep='', 'results/',r,'-0.2-0.3-',den,'-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d[2:7] <- NULL
            d <- ddply(d, "Time", numcolwise(sum))
            d$Count <- ped
            d$Run <- r
            d$Density <- den

            if(length(data) == 0){
                data =  d
            }
            else{
                data = rbind(d,data)
            }
        }
    }
}

detach(package:plyr)
dd <- data %>% group_by(Density,Count,Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

ddd = dd[0:4]
names(ddd)[names(ddd) == "Mean"] <- "PacketRaw"

ddd<- ddd[c(3,4,2,1)]


b <- read.csv(file="results/baseline-ped-40.csv")
b$Count="40"

o <- c(80,160,320,640)
for (j in o){
    g = read.csv(paste(sep='','results/baseline-ped-',j,'.csv'))
    g$Count = j
    b = rbind(b,g)
}
b$Density= "Baseline"

bb<- b[c(1,2,4,5)]

bd = rbind(bb,ddd)

g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Density)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count)
ggsave("graphs/pdfs/var-car-var-ped-ld-comparison-traffic", plot=g, width=9, height=5, device=cairo_pdf)


suppressPackageStartupMessages(library(plyr))
data = c()
pedCount = c(40,80,160,320,640)
distance = c(100,300)


for (dis in distance){
    for (ped in pedCount){
        for (r in 1:10){
            f = file(paste(sep='', 'results/',r,'-0.2-0.3-ld-',ped,'-ped-12-poi-6-pro-',dis,'-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d[2:7] <- NULL
            d <- ddply(d, "Time", numcolwise(sum))
            d$Count <- ped
            d$Run <- r
            d$Distance <- dis

            if(length(data) == 0){
                data =  d
            }
            else{
                data = rbind(d,data)
            }
        }
    }
}

detach(package:plyr)
dd <- data %>% group_by(Distance,Count,Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

g <- ggplot(dd,aes(x=Time,y=Mean, color=Distance)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count)

g2 <- ggplot(dd, aes(x=Time)) +
    geom_bar(stat="identity", aes(y=Mean), position="dodge") +
      geom_errorbar(aes(ymin=Min, ymax=Max, group=Time), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
      theme_custom() + facet_wrap(~Count)
