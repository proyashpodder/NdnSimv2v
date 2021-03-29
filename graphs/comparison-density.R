suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)
Density = c("ld","md","hd")

for (den in Density){
    for (ped in pedCount){
        for (r in 1:10){
            f = file(paste(sep='', 'results/near-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d[2:7] <- NULL
            d <- ddply(d, "Time", numcolwise(sum))
            d$Count <- ped
            d$Run <- r
            if(den == "ld" )
                d$Type <- "Low Density"
            else if (den == "md")
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

                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=Mean,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, Low, Medium and High Density vehicle in single hop scenario for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean of 10 runs)")

grob <- grobTree(textGrob("Low Density = 0-15 veh/mile/lane", x=0.1,  y=0.95, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))
grob1 <- grobTree(textGrob("Medium Density = 16-30 veh/mile/lane", x=0.1,  y=0.85, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))
grob2 <- grobTree(textGrob("High Density = 31-45 veh/mile/lane", x=0.1,  y=0.75, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))

g + annotation_custom(grob) + annotation_custom(grob1) + annotation_custom(grob2)

ggsave("graphs/pdfs/ld-comparison-basline-multi-single-traffic", plot=g, width=9, height=5, device=cairo_pdf)






suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)

for (ped in pedCount){
    f = file(paste(sep='', 'results/40-near-1-0.2-0.45-hd-',ped,'-ped-12-poi-6-pro-300-consumerdistance.csv'))
    d = read.table(f,header=TRUE)
    d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
    d[2:7] <- NULL
    d <- ddply(d, "Time", numcolwise(sum))
    d$Count <- ped

    if(length(data) == 0){
        data =  d
    }
    else{
        data = rbind(d,data)
    }
}

detach(package:plyr)
dd <- data %>% group_by(Count) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

dd$Type= "40 PSCCH"

suppressPackageStartupMessages(library(plyr))
for (ped in pedCount){
    f = file(paste(sep='', 'results/near-1-0.0001-0.5-hd-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
    d = read.table(f,header=TRUE)
    d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
    d[2:7] <- NULL
    d <- ddply(d, "Time", numcolwise(sum))
    d$Count <- ped

    if(length(data) == 0){
        data =  d
    }
    else{
        data = rbind(d,data)
    }
}

detach(package:plyr)
ddd <- data %>% group_by(Count) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

ddd$Type= "23 PSCCH"


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

bd = rbind(bdd,dd,ddd)
bd$Count = factor(bd$Count, levels=c(40,80,160,320,640), ordered=TRUE)

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=Mean,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, single and multiple Interest total traffic for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean)")

ggsave("graphs/pdfs/hd-23-40-pssch.pdf", plot=g, width=9, height=5, device=cairo_pdf)












suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)
Density = c("12-ld","8-md","4-hd")

for (den in Density){
    for (ped in pedCount){
        for (r in 1:5){
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

grob <- grobTree(textGrob("Low Density = 0-15 veh/mile/lane", x=0.1,  y=0.95, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))
grob1 <- grobTree(textGrob("Medium Density = 16-30 veh/mile/lane", x=0.1,  y=0.85, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))
grob2 <- grobTree(textGrob("High Density = 31-45 veh/mile/lane", x=0.1,  y=0.75, hjust=0,
  gp=gpar(col="red", fontsize=13, fontface="italic")))

g + annotation_custom(grob) + annotation_custom(grob1) + annotation_custom(grob2)

ggsave("graphs/pdfs/ld-comparison-basline-multi-single-traffic", plot=g, width=9, height=5, device=cairo_pdf)
