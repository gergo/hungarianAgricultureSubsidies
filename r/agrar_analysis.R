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
list.of.packages <-c("plyr",
                     "ggplot2",
                     "data.table",
                     "tidyverse",
                     "reshape2",
                     "plot3D"
                     )


new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)>0) {install.packages(new.packages)}
lapply(list.of.packages, require, character.only = TRUE)

dir <- getwd()
data_in <- paste0(dir,"/../output/")
data_out <- paste0(dir,"/../imgs/")

agrar_funds <- read.csv(paste0(data_in, "agrar_funds.csv"),
                              header = TRUE, stringsAsFactors = F)
agrar_wins <- read.csv(paste0(data_in, "agrar_wins.csv"),
                              header = TRUE, stringsAsFactors = F) %>%
              filter(amount>0)
agrar_winners <- read.csv(paste0(data_in, "agrar_winners.csv"),
                              header = TRUE, stringsAsFactors = F)
agrar_settlements <- read.csv(paste0(data_in, "agrar_settlements.csv"),
                              header = TRUE, stringsAsFactors = F)

agrar_full <- join(agrar_wins, agrar_winners, by = "winner_id")
agrar_full <- join(agrar_full, agrar_funds, by = "fund_id")
agrar_full <- join(agrar_full, agrar_settlements, by = "settlement_id")

rm(agrar_wins)
rm(agrar_winners)
rm(agrar_funds)
rm(agrar_settlements)

agrar_full$land_based <- as.factor(agrar_full$land_based)
agrar_full$is_capital <- as.factor(agrar_full$is_capital)
agrar_full$settlement_type <- as.factor(agrar_full$settlement_type)

agrar_full$winner_id <- NULL;
agrar_full$fund_id <- NULL;
agrar_full$settlement_id <- NULL;

options(scipen=999)
set.seed(42)

##########################
# Basic stats about wins
##########################
amount <- agrar_full$amount
# Save the mean, sd, min, max, quantiles of won amounts
descr_amount <- as.matrix( c( mean(amount) , sd(amount), min(amount) , max(amount) , quantile(amount,.50), quantile(amount,.95) , length(amount) ) )
# Name the dimensions as a list to have neat output 
dimnames(descr_amount)[[1]] <- list('mean','sd','min','max', 'p50' , 'p95' , 'n')
print(descr_amount)

##########################
# Yearly distribution of amounts
##########################
save_3d_chart <- function(data, bins, target_var, dataset) {
  years <- 9

  chart_data <- data %>%
    group_by(year) %>%
    mutate(rank = ntile(amount,bins)) %>%
    group_by(year,rank) %>%
    summarise(cnt=n(),
              log_avg=log(mean(amount)),
              avg=mean(amount),
              sum=sum(amount)) %>%
    arrange(desc(year)) %>%
    dcast(rank ~ year, value.var = target_var) %>%
    column_to_rownames(var = "rank") %>%
    as.matrix()
  
  hist3D(x = 1:bins, y = 1:years, z = chart_data,
                bty = "g", phi = 20,  theta = -50,
                main = paste0(dataset, " - ", target_var," - ",bins," bins"),
                xlab = "bins", ylab = "years", zlab = target_var,
                border = "black", shade = 0.3,
                space = 0.2, d = 4)
  # Use text3D to label x axis
  # text3D(x = 1:bins, y = rep(0.5, bins), z = rep(8, bins),
  #       labels = rownames(chart_data),
  #       add = TRUE, adj = 0)
  # Use text3D to label y axis
  # text3D(x = rep(1, years),   y = 1:years, z = rep(7, years),
  #       labels  = colnames(chart_data),
  #       add = TRUE, adj = 1)
  
  # save image
  png(filename=paste0(data_out, dataset,"_",target_var,"_",bins,".png"))
  plotdev()
  dev.off()
}

full_by_year <- agrar_full %>%
  select(year,amount,land_based,is_firm,is_capital)

save_3d_chart(full_by_year, 10, "log_avg", "all")
save_3d_chart(full_by_year, 10, "avg", "all")
save_3d_chart(full_by_year, 10, "sum", "all")

firm_by_year <- agrar_full %>%
  filter(is_firm == TRUE) %>%
  select(year,amount,land_based,is_firm,is_capital)

save_3d_chart(firm_by_year, 10, "log_avg", "firms")
save_3d_chart(firm_by_year, 10, "avg", "firms")
save_3d_chart(firm_by_year, 10, "sum", "firms")

individuals_by_year <- agrar_full %>%
  filter(is_firm == FALSE) %>%
  select(year,amount,land_based,is_firm,is_capital)

save_3d_chart(individuals_by_year, 10, "log_avg", "individuals")
save_3d_chart(individuals_by_year, 10, "avg", "individuals")
save_3d_chart(individuals_by_year, 10, "sum", "individuals")


