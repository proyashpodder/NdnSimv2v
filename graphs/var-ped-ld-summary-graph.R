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




suppressPackageStartupMessages(library(plyr))
data = c()
pedCount = c(40,80,160,320,640)


for (ped in pedCount){
    for (r in 1:5){
        f = file(paste(sep='', 'results/',r,'-0.2-0.3-ld-',ped,'-ped-12-poi-6-pro-300-consumerdistance.csv'))
        d = read.table(f,header=TRUE)
        d = subset(d, FaceDescr=="lte://" & (Type == "OutInterests" | Type == "OutData"))
        d[2:7] <- NULL
        d <- ddply(d, "Time", numcolwise(sum))
        #d <- ddply(d, "r", numcolwise(sum))
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
#d$Count = factor(d$Count, levels=c(10,20,30,40), ordered=TRUE)

detach(package:plyr)
ru <- data %>% group_by(Count,Run) %>% summarise(PacketRaw = sum(PacketRaw))

dd <- ru %>% group_by(Count,Time) %>% summarise(Mean=mean(PacketRaw),Min=min(PacketRaw),Max=max(PacketRaw))  %>% ungroup()
g2 <- ggplot(dd, aes(x=factor(Count))) +
    geom_bar(stat="identity", aes(y=Mean), position="dodge") +
      geom_errorbar(aes(ymin=Min, ymax=Max, group=Count), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) + ggtitle("Total number of packets (mean) for various pedestrian count") + xlab("Number of pedestrians") + ylab("Number of Packets") +
      theme_custom() 
ggsave("graphs/pdfs/var-ped-ld-20-run-300-traffic-errorgraph.pdf", plot=g2, width=9, height=5, device=cairo_pdf)
