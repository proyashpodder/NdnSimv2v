suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)
type = c(100,300)

for (t in type){
    for (ped in pedCount){
        for (r in 1:5){
            f = file(paste(sep='', 'results/near-',r,'-0.0001-0.5-hd','-',ped,'-ped-12-poi-6-pro-',t,'-consumerdistance.csv'))
            d = read.table(f,header=TRUE)
            d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
            d[2:7] <- NULL
            d <- ddply(d, "Time", numcolwise(sum))
            d$Count <- ped
            d$Run <- r
            if(t == 100 )
                d$Type <- "Single Hop"
            else
                d$Type <- "Multiple Hops"

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
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean of 20 runs)")
ggsave("graphs/pdfs/ld-comparison-basline-multi-single-traffic", plot=g, width=9, height=5, device=cairo_pdf)









suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)
density = c("ld","md","hd")
hopCount = c(100,300)

for (hop in hopCount){
    for (den in density){
        for (ped in pedCount){
            for (r in 1:2){
                f = file(paste(sep='', 'results/near-',r,'-0.0001-0.5-',den,'-',ped,'-ped-12-poi-6-pro-',hop,'-consumerdistance.csv'))
                d = read.table(f,header=TRUE)
                d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
                d[2:7] <- NULL
                d <- ddply(d, "Time", numcolwise(sum))
                d$Count <- ped
                d$Run <- r
                
                if(den == "hd")
                    d$Density <- "High Density"
                else if(den =="md")
                    d$Density <- "Medium Density"
                else
                    d$Density <- "Low Density"
                    
                if(hop == 100)
                    d$Hop = "Single Hop"
                else
                    d$Hop = "Multiple Hops"

                if(length(data) == 0){
                    data =  d
                }
                else{
                    data = rbind(d,data)
                }
            }
        }
    }
}

data$Count = factor(data$Count, levels=c(40,80,160,320,640), ordered=TRUE)

detach(package:plyr)
ru <- data %>% group_by(Density,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

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
b$Density = "Baseline"
b$Count = factor(b$Count, levels=c(40,80,160,320,640), ordered=TRUE)

bb<- b[c(1,2,4,5)]

bdd <- bb %>% group_by(Density,Count) %>% summarise(Mean=sum(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()

bd = rbind(bdd,dd)



                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=Mean,
                         group=Density,
                         fill=Density)) +
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean of 20 runs)")




data = c()
for (r in 1:10){
    f = file(paste(sep='', 'results/',r,'-0.2-0.3-ld-320-ped-12-poi-6-pro-100-consumerdistance.csv'))
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

detach(package:plyr)
dd <- data %>% group_by(Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))
dd$Type = "Sngle Interest"

suppressPackageStartupMessages(library(plyr))
data = c()
for (r in 1:10){
    f = file(paste(sep='', 'results/four-',r,'-0.2-0.3-ld-320-ped-12-poi-6-pro-100-consumerdistance.csv'))
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

detach(package:plyr)
ddd <- data %>% group_by(Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))
ddd$Type = "Multiple Interest"






suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)


    for (ped in pedCount){
        for (r in 1:5){
            f = file(paste(sep='', 'results/',r,'-0.0001-0.5-ld','-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
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

data$Type = "Single Interest"
detach(package:plyr)
ru <- data %>% group_by(Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

s <- ru %>% group_by(Type,Count) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()



#ddd = dd[0:4]
#names(ddd)[names(ddd) == "Mean"] <- "PacketRaw"

#ddd<- ddd[c(3,4,2,1)]

suppressPackageStartupMessages(library(plyr))

data = c()
pedCount = c(40,80,160,320,640)


    for (ped in pedCount){
        for (r in 1:5){
            f = file(paste(sep='', 'results/four-',r,'-0.0001-0.5-ld','-',ped,'-ped-12-poi-6-pro-100-consumerdistance.csv'))
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
data$Type = "Multiple Interest"

detach(package:plyr)
mu <- data %>% group_by(Type,Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

m <- mu %>% group_by(Type,Count) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()






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

bd = rbind(bdd,s,m)
bd$Count = factor(bd$Count, levels=c(40,80,160,320,640), ordered=TRUE)

                                        #g <- ggplot(bd,aes(x=Time,y=PacketRaw, color=Type)) + geom_line(size=0.6)+theme_custom() +facet_wrap(~Count) +ggtitle("Comparison among baseline, singlehop and multihop total traffic for various pedestrain count") + xlab("Time(s)") + ylab("Number of Total Packets (Mean of 20 runs)")

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=Mean,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, single and multiple Interest total traffic for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets (Mean)")
ggsave("graphs/pdfs/ld-comparison-basline-multi-single-traffic", plot=g, width=9, height=5, device=cairo_pdf)




suppressPackageStartupMessages(library(plyr))
pedCount = c(40,80,160,320,640)
data= c()
for (ped in pedCount){
    f = file(paste(sep='', 'results/modified-simulation-hd-',ped,'.csv'))
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
mu <- data %>% group_by(Count) %>% summarise(PacketRaw = sum(PacketRaw))

mu$Type= "High Density"

suppressPackageStartupMessages(library(plyr))
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

bdd <- b %>% group_by(Count) %>% summarise(Mean=sum(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()


bd = rbind(b,data)
bd$Count = factor(bd$Count, levels=c(40,80,160,320,640), ordered=TRUE)

g <- ggplot(data=bd, aes(x=factor(Count),
                        y=PacketRaw,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") +theme_custom()+ ggtitle("Comparison among baseline, and multiple Interest total traffic for various pedestrain count") + xlab("Number of Pedestrians") + ylab("Number of Total Packets")
