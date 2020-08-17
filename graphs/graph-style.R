theme_custom <- function (base_size = 10, base_family = "serif") {
  theme_grey(base_size = base_size, base_family = base_family) %+replace%
    theme(
      line =               element_line(colour = "black", size = 0.5, linetype = 1, lineend = "butt"),
      rect =               element_rect(fill = "white", colour = "black", size = 0.5, linetype = 1),
      text =               element_text(family = base_family, face = "plain", colour = "black", size = base_size, hjust = 0.5, vjust = 0.5, angle = 0, lineheight = 0.5, margin=margin(0.1, 0.1, 0.1, 0.1, unit="cm"), debug=FALSE),
      axis.text =          element_text(size = rel(0.8), colour = "grey50"),
      strip.text =         element_text(size = rel(0.8)),

      axis.line =          element_blank(),
      axis.text.x =        element_text(family = base_family, size = base_size * 0.7, lineheight = 0.8, vjust = 1.2),
      axis.text.y =        element_text(family = base_family, size = base_size * 0.7, lineheight = 0.8, hjust = 1.2),
      axis.ticks =         element_line(colour = "black", size=0.2),
      axis.title.x =       element_text(family = base_family, size = base_size, vjust = 0.5),
      axis.title.y =       element_text(family = base_family, size = base_size, angle = 90, vjust = 0.5),
      axis.ticks.length =  unit(0.15, "cm"),
      ## axis.ticks.margin =  unit(0.1, "cm"),
          
      legend.background =  element_rect(fill=NA, colour=NA, size=0.05),
      legend.margin =      margin(0.05, 0.05, 0.05, 0.05, "cm"),
      legend.key =         element_rect(fill = "grey95", colour = "white"),
      legend.key.size =    unit(0.9, "cm"),
      legend.key.height =  unit(0.5, "lines"),
      legend.key.width =   NULL,
      legend.text =        element_text(family = base_family, size = base_size * 0.6),
      legend.text.align =  NULL,
      legend.title =       element_text(family = base_family, size = base_size * 0.6, face = "bold", hjust = 0),
      legend.title.align = NULL,
      legend.position =    "right",
      legend.direction =   NULL,
      legend.justification = "center",
      legend.box =         NULL,
  
      panel.background =   element_rect(fill = "white", colour = NA),
      panel.border =       element_rect(fill = NA, colour = "grey50"),
      panel.grid.major =   element_line(colour = "grey60", size = 0.1),
      panel.grid.minor =   element_line(colour = "grey70", size = 0.1, linetype="dotted"),
      ## panel.margin =       unit(c(0.1, 0.1, 0.1, 0.1), "lines"),
  
      strip.background =   element_rect(fill = NA, colour = NA),
      strip.text.x =       element_text(family = base_family, size = base_size * 0.8),
      strip.text.y =       element_text(family = base_family, size = base_size * 0.8, angle = -90),
  
      plot.background =    element_rect(colour = NA, fill = "white"),
      plot.title =         element_text(family = base_family, size = base_size),
      plot.margin =        unit(c(0, 0, 0, 0), "lines")
    )
}

