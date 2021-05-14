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




FOLDER = "1-hop-result"

data = c()
pedCount = c(40,80,160,320,640)
Density = c("12-ld","8-md","4-hd")

## data = c()
## pedCount = c(80)
## Density = c("8-md")

for (den in Density){
    for (ped in pedCount){
        for (r in 1:2) {
            filename = paste(sep='', FOLDER,'/nowTime-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv')

                f = file(filename)
                d = read.table(f,header=TRUE)
                d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
                d$Type = factor(d$Type)
                
                d <-  d %>%
                    select(Time,Type,PacketRaw) %>%
                    group_by(Time = cut(Time, breaks = seq(0.0,60.0,10)),
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

ru3 <- data %>% group_by(Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

dd3 <- ru3 %>% group_by(Type,Count) %>%
    summarise(Mean=mean(PacketRaw),StdDev=sd(PacketRaw),NPoints=n()) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()
dd3$Type = factor(dd3$Type, levels=c("Low Density", "Medium Density", "High Density", "Baseline"), ordered=TRUE)
dd3$Count <- factor(dd3$Count, levels=pedCount, ordered=FALSE)



b <- read.csv(file="results/baseline-ped-40.csv")
b$Count="40"

o <- c(80,160,320,640)
for (j in o){
    g = read.csv(paste(sep='','results/baseline-ped-',j,'.csv'))
    g$Count = j
    b = rbind(b,g)
}
b$Type = "Baseline"

bdd <- b %>% group_by(Type,Count) %>% summarise(Mean=sum(PacketRaw))  %>% ungroup()
dd4 =dd3[1:3]
d = rbind(dd4,bdd)
d$Count = factor(d$Count, levels=c(40,80,160,320,640), ordered=TRUE)
d$Type = factor(d$Type, levels=c("Low Density","Medium Density","High Density","Baseline"), ordered=TRUE)

g <- ggplot(data=d, aes(x=factor(Count),
                        y=Mean,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") + theme_custom()+ ggtitle("Comparison among baseline, Low, Medium and High Density vehicle in single hop scenario for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean of 10 runs)")

ggsave("graphs/pdfs/new-single-hop-comparison.pdf", plot=g, width=9, height=5, device=cairo_pdf)
