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

data = c()
pedCount = c(40,80,160,320,640)
Density = c("12-ld","8-md","4-hd")

data = c()
pedCount = c(80)
Density = c("8-md")

detach(package:plyr)

Intersection=c(500,500,0)

dist = function(pos) {
    out = vector(mode="numeric",length=length(pos))
    for (i in 1:length(pos)) {
        point = as.numeric(unlist(strsplit(pos[i], ",")))
        out[i] = sqrt(sum((point - Intersection)^2))
    }
    return (out)
}

dist = function(pos) {
    out = vector(mode="numeric",length=length(pos))
    for (i in 1:length(pos)) {
        tryCatch({
        print("before")
        point = as.numeric(unlist(strsplit(pos[i], ",")))
        out[i] = sqrt(sum((point - Intersection)^2))
        print("after")
        }, warning = function(w) {
            print(w)
        }, error = function(e) {
            print(e)
        }, finally = {
        })
    }
    return (out)
}





for (den in Density){
    for (ped in pedCount){
        for (r in 1:10){
            f = file(paste(sep='', 'results/nowTime-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-300-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d$Type = factor(d$Type)
            d$Distance = dist(d$NodePosition)
            #print(d$Distance)
            ## d[2:7] <- NULL
            
            d <-  d %>%
                select(Time,Type,PacketRaw,Distance) %>%
                group_by(Time = cut(Time, breaks = seq(0.0,60.0,10)),
                         Distance = cut(Distance, breaks = seq(0, 500, 50)),
                         PacketType = Type) %>%
                summarize(PacketRaw = sum(PacketRaw))
            
            d$Count <- factor(ped, levels=pedCount, ordered=FALSE)
            d$Run <- r
            if (den == "12-ld")
                d$Type <- factor("Low Density")
            else if (den == "8-md")
                d$Type<- factor("Medium Density")
            else
                d$Type <- factor("High Density")

            if(length(data) == 0){
                data =  d
            }
            else {
                data = rbind(d,data)
            }
        }
    }
}

ru <- data %>% group_by(Distance,PacketType,Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

dd <- ru %>% group_by(Distance,PacketType,Type,Count) %>%
    summarise(Mean=mean(PacketRaw),StdDev=sd(PacketRaw),NPoints=n()) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()

#ddd = dd[0:4]
#names(ddd)[names(ddd) == "Mean"] <- "PacketRaw"

#ddd<- ddd[c(3,4,2,1)]

b <- read.csv(file="results/baseline-ped-40.csv")
b$Count="40"

o <- c(80,160,320,640)
for (j in o){
    g = read.csv(paste(sep='','results/baseline-ped-',j,'.csv'))
    g$Count = j
    b = rbind(b,g)
}
b$Type = "Baseline"



## g  <- ggplot(data) +
##     geom_point(aes(x=Time, y=PacketRaw, group=Type, colour=Distance, shape=PacketType))


## bb<- b[c(1,2,4,5)]

## bdd <- bb %>% group_by(Type,Count) %>% summarise(Mean=sum(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

## bd = rbind(bdd,dd)

## bd$Count = factor(bd$Count, levels=c(40,80,160,320,640), ordered=TRUE)

bd = dd
bd$Type = factor(bd$Type, levels=c("Low Density","Medium Density","High Density","Baseline"), ordered=TRUE)

                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

g <- ggplot(data=bd, aes(x=Count,
                         y=Mean,
                         group=Distance,
                         colour=Distance,
                         fill=Type)) +
    geom_bar(position="dodge", stat="identity", colour="black") +
    geom_errorbar(aes(ymin=Min, ymax=Max), size=I(0.3), width=I(0.4), position=position_dodge(width=1))+
    theme_custom()+
    ggtitle("Comparison among baseline, Low, Medium and High Density vehicle in single hop scenario for various pedestrain count") + xlab("Number of Pedestrians") +
    ylab("Number of Total Packets (Mean of 10 runs)") +
    facet_wrap(~ PacketType)

ggsave("graphs/pdfs/multi-hops-comparison.pdf", plot=g, width=9, height=5, device=cairo_pdf)
