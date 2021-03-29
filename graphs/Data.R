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

for (ped in pedCount){
    for (r in 1:5){
        f = file(paste(sep='', 'results/nowTime-',r,'-0.0001-0.5-hd4-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
        d = read.table(f,header=TRUE)
        d = subset(d, FaceDescr=="lte://" & (Type == "OutData"))
        d[2:7] <- NULL
        d <- ddply(d, "Time", numcolwise(sum))
        d$Count <- ped
        d$Run = r
    
        if(length(data) == 0){
            data =  d
        }
        else{
            data = rbind(d,data)
        }
    }
}

detach(package:plyr)
ru <- data %>% group_by(Count, Run) %>% summarise(PacketRaw = sum(PacketRaw))

dd <- ru %>% group_by(Count) %>% summarise(TotalPacket=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()


g <- ggplot(data=dd, aes(x=factor(Count),
                        y=TotalPacket)) +
 geom_bar(position="dodge", stat="identity", colour="black") +
geom_errorbar(aes(ymin=Min, ymax=Max, group=Count), size=I(0.3), width=I(0.4), position=position_dodge(width=1))+ theme_custom()+ ggtitle("Total Number of Data Packets for varioud pedestrian count") + xlab("Number of Pedestrians") + ylab("Number of Total Data Packets") + scale_y_continuous(limits = c(0, 1000))

ggsave("graphs/pdfs/Data.pdf", plot=g, width=9, height=5, device=cairo_pdf)

