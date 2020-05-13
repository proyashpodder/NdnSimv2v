suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

data=data.frame(nodenumber=double(), timeTogetData=double())
t = read.csv(file="results/fixedmultihopnodenumber-1.csv")
data = rbind(t,data)
g <- ggplot(data, aes(y = timeTogetData, x = nodenumber)) + geom_point() + theme_custom() + scale_size_manual(values=c(4,1))
ggsave("graphs/pdfs/data-time-nodenumber.pdf", plot=g+scale_y_continuous(name="data-retrieval time (s)", limits=c(0,1))+scale_x_continuous(name="number of nodes", breaks=seq(10,100,10)), width=8, height=4, device=cairo_pdf)
