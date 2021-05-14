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




detach(package:plyr)

Intersection=c(500,500,0)


dist = function(pos) {
    out = vector(mode="numeric",length=length(pos))
    for (i in 1:length(pos)) {
        
        point = as.numeric(unlist(strsplit(pos[i], ",")))
        out[i] = sqrt(sum((point - Intersection)^2))
        
        ## tryCatch({
        ## point = as.numeric(unlist(strsplit(pos[i], ",")))
        ## out[i] = sqrt(sum((point - Intersection)^2))
        ## }, warning = function(w) {
        ##     print(w)
        ## }, error = function(e) {
        ##     print(e)
        ## }, finally = {
        ## })
    }
    return (out)
}



FOLDER = "res-new/result_files"

data = c()
pedCount = c(40,80,160,320,640)
Density = c("12-ld","8-md","4-hd")

## data = c()
## pedCount = c(80)
## Density = c("8-md")

for (den in Density){
    for (ped in pedCount){
        for (r in 1:10) {
            filename = paste(sep='', FOLDER,'/nowTime-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-300-consumerdistance.csv')
            ## filenameProcessed = paste(sep='', filename, '-processed.csv')
            ## if (file.exists(filenameProcessed)) {
            ##     f = file(filenameProcessed)
            ##     d = read.table(f, header=TRUE)
            ## }
            ## else {
                f = file(filename)
                d = read.table(f,header=TRUE)
                d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
                d$Type = factor(d$Type)
                d$Distance = dist(d$NodePosition)
                                        #print(d$Distance)
                ## d[2:7] <- NULL
                
                d <-  d %>%
                    select(Time,Type,PacketRaw,Distance) %>%
                    group_by(Time = cut(Time, breaks = seq(0.0,60.0,10)),
                             Distance = cut(Distance, breaks = c(0,60,120,240,360,480)),
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

            ##     write.table(d, filenameProcessed)
            ## }

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

# dd data with packet types
dd <- ru %>% group_by(Distance,PacketType,Type,Count) %>%
    summarise(Mean=mean(PacketRaw),StdDev=sd(PacketRaw),NPoints=n()) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()


ru2 <- data %>% group_by(Distance,Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

# dd2 data without packet types
dd2 <- ru2 %>% group_by(Distance,Type,Count) %>%
    summarise(Mean=mean(PacketRaw),StdDev=sd(PacketRaw),NPoints=n()) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()

ru3 <- data %>% group_by(Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

# dd3 data without packet types and distances
dd3 <- ru3 %>% group_by(Type,Count) %>%
    summarise(Mean=mean(PacketRaw),StdDev=sd(PacketRaw),NPoints=n()) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()
dd3$Type = factor(dd3$Type, levels=c("Low Density", "Medium Density", "High Density", "Baseline"), ordered=TRUE)
dd3$Count <- factor(dd3$Count, levels=pedCount, ordered=FALSE)



b <- read.csv(file=paste(sep='', FOLDER, "/baseline-ped-40.csv"))
b$Count="40"

o <- c(80,160,320,640)
for (j in o){
    g = read.csv(paste(sep='', FOLDER,'/baseline-ped-',j,'.csv'))
    g$Count = j
    b = rbind(b,g)
}
b$Type = "Baseline"


## g  <- ggplot(data) +
##     geom_point(aes(x=Time, y=PacketRaw, group=Type, colour=Distance, shape=PacketType))

b$Count = factor(b$Count, levels=c(40,80,160,320,640), ordered=TRUE)
b$Distance = factor("(0,60]")
## bb$PacketType = factor("IP")

bdd <- b %>% group_by(Distance, Type, Count) %>%
    summarise(Mean=sum(PacketRaw),StdDev=0,NPoints=1) %>%
    mutate(Min=Mean - qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints),
           Max=Mean + qt(1 - (0.05 / 2), NPoints - 1) * StdDev/sqrt(NPoints)) %>%
    ungroup()

bd = rbind(bdd,dd2)
bd$Type = factor(bd$Type, levels=c("Low Density", "Medium Density", "High Density", "Baseline"), ordered=TRUE)

                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

bd1 = subset(bd, !is.na(Distance))

bd1$Distance <- factor(bd1$Distance, levels=rev(levels(bd1$Distance)))

bd2 = bd1
for (row in 1:nrow(bd1)) {
    x = subset(bd1, as.numeric(Distance) >= as.numeric(bd1[row,]$Distance) &
                    Type==bd1[row,]$Type &
                    Count==bd1[row,]$Count)
    adjusted = sum(x$Mean)
    bd2[row,]$Min = bd2[row,]$Min - bd2[row,]$Mean + adjusted
    bd2[row,]$Min = bd2[row,]$Max - bd2[row,]$Mean + adjusted
    bd2[row,]$Mean = adjusted
}

ddd3 = rbind(dd3, subset(bdd, select=-Distance))

g <- ggplot(data=bd2, aes(x=Count,
                         y=Mean,
                         group=Type,
                         fill=Type)) +
    geom_bar(aes(linetype=Distance), position="dodge", stat="identity", colour="black", alpha=0.1) +
    geom_errorbar(data=ddd3, aes(ymin=Min, ymax=Max), size=I(0.3), width=I(0.2), position=position_dodge(width=0.9))+
    theme_custom()+
    xlab("Number of Pedestrians") +
    ylab("Number of Total Packets (Mean of 10 runs)")

    ## ggtitle("Comparison among baseline, Low, Medium and High Density vehicle in multi hop scenario for various pedestrain count") +

## +
    ## facet_wrap(~ PacketType)

ggsave("graphs/multi-hops-comparison.pdf", plot=g, width=6, height=3.5, device=cairo_pdf)
