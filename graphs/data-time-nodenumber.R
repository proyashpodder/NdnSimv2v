suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

data=data.frame(distance=double(), timeTogetData=double())
t = read.csv(file="results/fixedmultihopnodenumber.csv")
data = rbind(t,data)
g <- ggplot(data, aes(y = timeTogetData, x = distance)) + geom_point() + theme_custom() + scale_size_manual(values=c(4,1))
ggsave("graphs/pdfs/demo-data-time-nodenumber.pdf", plot=g+scale_y_continuous(name="data-retrieval time (s)", limits=c(1, 2))+scale_x_continuous(name="number of nodes", limits=c(10,90)), width=8, height=4, device=cairo_pdf)
