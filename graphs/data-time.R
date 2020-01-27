suppressPackageStartupMessages (library(ggplot2))
suppressPackageStartupMessages (library(dplyr))
suppressPackageStartupMessages (library(tidyr))

source ("graphs/graph-style.R")

data=data.frame(distance=double(), timeTogetData=double())
t = read.csv(file="results/datahop.csv")
data = rbind(t,data)
g <- ggplot(data, aes(y = timeTogetData, x = distance)) + geom_point() + theme_custom() + scale_size_manual(values=c(4,1))
ggsave("graphs/pdfs/demo-data-time-distance.pdf", plot=g+scale_y_continuous(name="data-retrieval time (s)", limits=c(0, 3))+scale_x_continuous(name="distance (m)", limits=c(100,1000)), width=8, height=4, device=cairo_pdf)
