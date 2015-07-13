#!/usr/bin/env Rscript
ud <- read.csv('./data/UD_vills_CCODE01.csv', stringsAsFactors=F)
rggvy <- ud[c('DC_CODE01', 'vill_energ_date')]
rggvy <- rggvy[nchar(rggvy$vill_energ_date) > 0,]
rggvy$DC_CODE01 <- substring(rggvy$DC_CODE01, 2)
write.table(rggvy, './data/rggvy.csv', sep=",", col.names=F, row.names=F)
