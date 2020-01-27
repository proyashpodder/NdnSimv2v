suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

data=data.frame(distance=double(), timeTogetData=double())
t = read.csv(file="results/datahop.csv")
data = rbind(t,data)
g <- ggplot()+geom_line(aes(y = timeTogetData, x = distance),data=data) + theme_custom() + scale_size_manual(values=c(4,1)) + scale_x_continuous(breaks=seq(100,1000,50))
ggsave("graphs/pdfs/data-time.pdf", plot=g, width=8, height=4, device=cairo_pdf)
