#!/usr/bin/env Rscript

# Install dependencies
deps <- c("dplyr", "tidyr")
new.packages <- deps[!(deps %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages, repos="http://cran.rstudio.com/")
library(dplyr)
library(tidyr)

dist_month <- read.csv('data/districts_month.csv', header=F)
names(dist_month) <- c('district_key', 'year', 'month', 'satellite', 
               'count', 'vis_mean', 'vis_sd', 'vis_min', 'vis_median', 'vis_max')

distdist <- read.csv('data/districts_distribution.csv', header = F)
names(distdist) <- c('state', 'district', 'year', 'month', 'satellite', 'quintile', 'min', 'max')
distdist$min <- NULL
distdist$key <- sapply(distdist$quintile, function(x) paste("quintile",x,sep=""))
distdist$quintile <- NULL

maxes <- distdist %>% spread(key, max)

maxes$district_key <- gsub("\\s+","-",paste(tolower(maxes$state),
                                                  tolower(maxes$district),
                                                        sep="-"))
# Join with districts_month

tojoin <- maxes %>% select(year:quintile4, district_key)
joined <- dist_month %>% left_join(tojoin)
write.table(joined, 'data/districts_month.csv', sep=",",col.names=F, row.names=F, na="")
