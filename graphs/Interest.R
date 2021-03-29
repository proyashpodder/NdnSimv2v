suppressPackageStartupMessages(library(plyr))
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

ggsave("graphs/pdfs/number-of-Interest-being-flat.pdf", plot=g, width=9, height=5, device=cairo_pdf)




















dd$Type = "Interest"

pp= c()

for (p in period){
    for ( r in 1:5){
        f= read.csv(paste(sep='','results/',r,'consumerCount-distance-100-',p,'.csv'))
        pu <- f %>% group_by(Time) %>% summarise(PacketRaw = sum(CnsumerCount))
        pu$Period = p
        pu$Run = r
        if(length(pp) == 0){
            pp =  pu
        }
        else{
            pp = rbind(pp,pu)
        }
    }
}
du <- pp %>% group_by(Period,Run) %>% summarise(PacketRaw = sum(PacketRaw))
pppp <- du %>% group_by(Period) %>% summarise(TotalPacket=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()
pppp$Type= "Interest Without Suppression"
#ppp = pppp[c(2,1,3)]

new = rbind(pppp,dd)
new$Period = factor(new$Period, levels=c(16,8,4,2,1,0.5), ordered=TRUE)

g <- ggplot(data=new, aes(x=factor(Period),
                        y=TotalPacket,
                         group=Type,
                         fill=Type)) +
 geom_bar(position="dodge", stat="identity", colour="black") + geom_errorbar(aes(ymin=Min, ymax=Max, group=Type), size=I(0.3), width=I(0.4), position=position_dodge(width=1))+theme_custom() + xlab("Period of Car flow") + ylab("Number of Total Interest Packets") + scale_y_continuous(limits = c(0, 2000)) + geom_abline(slope=0, intercept=320,  col = "red",lty=2)

ggsave("graphs/pdfs/Interest-with-without-suppression.pdf", plot=g, width=9, height=5, device=cairo_pdf)
