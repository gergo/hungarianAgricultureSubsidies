############################################################
#
# Hungarian Agricultural Subsidies Analysis
# Gergo Szekely
#
############################################################  
# Data import
# Feature engineering
# Regression analysis 
# Graph creation
############################################################  

# CLEAR MEMORY
rm(list=ls())

# install missing packages
list.of.packages <- c("plyr",
                      "ggplot2",
                      "data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)>0) {install.packages(new.packages)}

lapply(list.of.packages, require, character.only = TRUE)

dir <- getwd()
data_in <- paste0(dir,"/../output/")
data_out <- paste0(dir,"/../analysis/")

agrar_funds <- read.csv(paste0(data_in, "agrar_funds.csv"),
                              stringsAsFactors = F)
agrar_wins <- read.csv(paste0(data_in, "agrar_wins.csv"),
                              stringsAsFactors = F)
agrar_winners <- read.csv(paste0(data_in, "agrar_winners.csv"),
                              stringsAsFactors = F)
agrar_settlements <- read.csv(paste0(data_in, "agrar_settlements.csv"),
                              stringsAsFactors = F)

agrar_full <- join(agrar_wins, agrar_winners, by = "winner_id")
agrar_full <- join(agrar_full, agrar_funds, by = "fund_id")

rm(agrar_funds)
rm(agrar_wins)
rm(agrar_winners)





