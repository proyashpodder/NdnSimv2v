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

for (den in Density){
    for (ped in pedCount){
        for (r in 1:10){
            f = file(paste(sep='', 'results/nowTime-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d[2:7] <- NULL
            d <- ddply(d, "Time", numcolwise(sum))
            d$Count <- ped
            d$Run <- r
            if(den == "12-ld" )
                d$Type <- "Low Density"
            else if (den == "8-md")
                d$Type<- "Medium Density"
            else
                d$Type <- "High Density"

            if(length(data) == 0){
                data =  d
            }
            else {
                data = rbind(d,data)
            }
        }
    }
}

detach(package:plyr)
ru <- data %>% group_by(Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

dd <- ru %>% group_by(Type,Count) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

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

bb<- b[c(1,2,4,5)]

bdd <- bb %>% group_by(Type,Count) %>% summarise(Mean=sum(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

bd = rbind(bdd,dd)
bd$Count = factor(bd$Count, levels=c(40,80,160,320,640), ordered=TRUE)
bd$Type = factor(bd$Type, levels=c("Low Density","Medium Density","High Density","Baseline"), ordered=TRUE)

                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=Mean,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") +geom_errorbar(aes(ymin=Min, ymax=Max), size=I(0.3), width=I(0.4), position=position_dodge(width=1))+ theme_custom()+ ggtitle("Comparison among baseline, Low, Medium and High Density vehicle in single hop scenario for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean of 10 runs)")

ggsave("graphs/pdfs/single-hop-comparison.pdf", plot=g, width=9, height=5, device=cairo_pdf)
