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


carCount = c(40,80,160,320,640)
data = c()
for (p in carCount){
    for (r in 1:5){
        f = file(paste(sep='', 'results/nowTime-',r,'-0.0001-0.5-',p,'-car-40-ped-12-poi-6-pro-100-consumerdistance.csv'))
        d = read.table(f,header=TRUE)
        d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests"))
        d[2:7] <- NULL
        d <- ddply(d, "Time", numcolwise(sum))
        d$CarCount = p
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
ru <- data %>% group_by(CarCount,Run) %>% summarise(PacketRaw = sum(PacketRaw))
dd <- ru %>% group_by(CarCount) %>% summarise(TotalPacket=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()
dd$CarCount = factor(dd$CarCount, levels=c(40,80,160,320,640), ordered=TRUE)

g <- ggplot(data=dd, aes(x=factor(CarCount),
                        y=TotalPacket)) +
 geom_bar(position="dodge", stat="identity", colour="black") + geom_errorbar(aes(ymin=Min, ymax=Max), size=I(0.3), width=I(0.4), position=position_dodge(width=1))+theme_custom() + xlab("Number of total cars in the simulation") + ylab("Number of Total Interest Packets") + scale_y_continuous(limits = c(0, 1000)) + geom_abline(slope=0, intercept=320,  col = "red",lty=2)

ggsave("graphs/pdfs/Interest.pdf", plot=g, width=9, height=5, device=cairo_pdf)
