suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

levels=seq(1,5,1)
data=data.frame(distance=double(), timeTogetData=double())
for(i in levels) {
      t=read.csv(file=paste(sep='','results/fixedmultihopnodenumber-',i,'.csv'), header= TRUE, sep="," )
      data = rbind(t, data)
}
my_sum<-data %>% group_by(nodenumber) %>% summarise(mean=mean(timeTogetData),Min=min(timeTogetData),Max=max(timeTogetData))
g2 <- ggplot(my_sum, aes(x=nodenumber)) +
     geom_bar(stat="identity", aes(y=mean), position="dodge") +
     geom_errorbar(aes(ymin=Min, ymax=Max, group=nodenumber), size=I(0.3), width=I(0.4), position=position_dodge(width=1)) +
     theme_custom()
ggsave("graphs/pdfs/error-graph-nodenumber.pdf", plot=g2+scale_y_continuous(name="Data-retrieval time (s)", limits=c(0,0.75))+scale_x_continuous(name="Number of nodes", breaks=seq(10,100,10)),, width=6, height=4, device=cairo_pdf)
