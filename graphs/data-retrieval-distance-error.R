suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

levels=seq(1,5,1)
data=data.frame(distance=double(), timeTogetData=double())
for(i in levels) {
      t=read.csv(file=paste(sep='','results/data-retrieval-distance-rng',i,'.csv'), header= TRUE, sep="," )
      data = rbind(t, data)
}
adjusted=data[0:2]
my_sum<-adjusted %>% group_by(distance) %>% summarise(mean=mean(timeTogetData),Min=min(timeTogetData),Max=max(timeTogetData))
g2 <- ggplot(my_sum, aes(x=distance)) +
     geom_bar(stat="identity", aes(y=mean), position="dodge") +
     geom_errorbar(aes(ymin=Min, ymax=Max, group=distance), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
     theme_custom()
ggsave("graphs/pdfs/error-graph.pdf", plot=g2+scale_y_continuous(name="Data-retrieval time (s)", limits=c(0,1.5))+scale_x_continuous(name="Distance (m)", breaks=seq(100,1000,50)),, width=6, height=4, device=cairo_pdf)


subdata <- subset(adjusted, distance==1000)
sub<-subdata[2]
sd <- sqrt(var(sub))
