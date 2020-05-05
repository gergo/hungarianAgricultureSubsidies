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
                     "plot3D",
                     "viridis"
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
agrar_full$year <- as.factor(agrar_full$year)
agrar_full$is_capital <- as.factor(agrar_full$is_capital)
agrar_full$is_capital <- recode(agrar_full$is_capital,
                                  `1` = "Budapest",
                                  `2` = "County capital",
                                  `3` = "Village or Town")

agrar_full$is_firm <- as.factor(agrar_full$is_firm)
agrar_full$settlement_type <- as.factor(agrar_full$settlement_type)

agrar_full$winner_id <- NULL
agrar_full$fund_id <- NULL
agrar_full$settlement_id <- NULL

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
rm(amount)


full_by_year <- agrar_full %>%
  select(year,amount,land_based,is_firm,is_capital)
full_by_year <- as.data.frame(full_by_year)
  

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
              log_sum=log(sum(amount)),
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
  # save image
  png(filename=paste0(data_out, "3d_",dataset,"_",target_var,"_",bins,".png"))
  plotdev()
  dev.off()
}

###################
# 3D charts
###################
save_3d_chart(full_by_year, 10, "log_avg", "all")
save_3d_chart(full_by_year, 10, "avg", "all")
save_3d_chart(full_by_year, 10, "sum", "all")

firm_by_year <- full_by_year %>%
  filter(is_firm == 1)

save_3d_chart(firm_by_year, 10, "log_avg", "firms")
save_3d_chart(firm_by_year, 10, "avg", "firms")
save_3d_chart(firm_by_year, 10, "sum", "firms")

individuals_by_year <- full_by_year %>%
  filter(is_firm == 0)

save_3d_chart(individuals_by_year, 10, "log_avg", "individuals")
save_3d_chart(individuals_by_year, 10, "avg", "individuals")
save_3d_chart(individuals_by_year, 10, "sum", "individuals")

rm(individuals_by_year)
rm(firm_by_year)

#########################
# individuals_land_based
#########################
individuals_land_based <- full_by_year %>%
  filter(is_firm == 0, land_based == 1)

save_3d_chart(individuals_land_based, 10, "log_avg", "individuals-land-based")
save_3d_chart(individuals_land_based, 20, "log_avg", "individuals-land-based")
save_3d_chart(individuals_land_based, 20, "sum", "individuals-land-based")
save_3d_chart(individuals_land_based, 50, "log_sum", "individuals-land-based")
save_3d_chart(individuals_land_based, 30, "avg", "individuals-land-based")
rm(individuals_land_based)

##############################
# individuals_not_land_based
##############################
individuals_not_land_based <- full_by_year %>%
  filter(is_firm == 0, land_based == 0)

save_3d_chart(individuals_not_land_based, 10, "log_avg", "individuals-decision-based")
save_3d_chart(individuals_not_land_based, 20, "log_avg", "individuals-decision-based")
save_3d_chart(individuals_not_land_based, 20, "sum", "individuals-decision-based")
save_3d_chart(individuals_not_land_based, 50, "log_sum", "individuals-decision-based")
save_3d_chart(individuals_not_land_based, 30, "avg", "individuals-decision-based")
rm(individuals_not_land_based)
rm(full_by_year)

##############################
# sum_by_address
##############################
sum_by_address <- agrar_full %>%
  select(year,zip,address,amount,land_based,is_firm) %>%
  mutate(land_based = as.factor(land_based),
         is_firm = as.factor(is_firm),
         year = as.factor(year)) %>%
  group_by(year,zip,address,land_based,is_firm) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address, 10, "avg", "summed-by-address")
save_3d_chart(sum_by_address, 30, "avg", "summed-by-address")
save_3d_chart(sum_by_address, 10, "log_avg", "summed-by-address")
save_3d_chart(sum_by_address, 30, "log_avg", "summed-by-address")
save_3d_chart(sum_by_address, 10, "sum", "summed-by-address")
save_3d_chart(sum_by_address, 30, "sum", "summed-by-address")

sum_by_address_decils <- sum_by_address %>%
  group_by(year) %>%
  mutate(rank = ntile(amount,10)) %>%
  mutate(rank = as.factor(rank)) %>%
  mutate(rank = fct_reorder(rank, desc(rank))) %>%
  group_by(year,rank) %>%
  summarise(sum=sum(amount)) %>%
  arrange(desc(year))

ggplot(data = sum_by_address_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme(axis.text.y = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_decils.png"))

ggplot(data = sum_by_address_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "Pct of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_decils_stacked.png"))

rm(sum_by_address_decils)
rm(sum_by_address)

sum_by_address_indiv <- agrar_full %>%
  filter(is_firm == 0, land_based == 0) %>% 
  select(year,zip,address,amount,land_based,is_firm) %>%
  group_by(year,zip,address,land_based,is_firm) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address_indiv, 10, "avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv, 10, "sum", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv, 10, "log_avg", "summed-by-address-indiv")
rm(sum_by_address_indiv)

sum_by_address_indiv_land <- agrar_full %>%
  filter(is_firm == 0, land_based == 1) %>% 
  select(year,zip,address,amount,land_based,is_firm) %>%
  group_by(year,zip,address,land_based,is_firm) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address_indiv_land, 10, "avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "log_avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "sum", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "log_sum", "summed-by-address-indiv")
rm(sum_by_address_indiv_land)

#########################
# 2D charts
#########################
ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = is_firm)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_isfirm.png"))


ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = land_based)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_land_based.png"))

ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = is_capital)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_is_capital.png"))

ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = source)) + 
  geom_bar(stat = "identity") +
  ylab("sum of total amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_source.png"))

######################
# stacked bar charts
#####################
ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = is_firm)) + 
  geom_bar(stat = "identity", position = "fill") +
  labs(y = "percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_isfirm_stacked.png"))

ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = land_based)) + 
  geom_bar(stat = "identity", position = "fill") +
  labs(y = "percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_land_based_stacked.png"))

ggplot(data = agrar_full, aes(x = year, y = amount/1000000000, fill = is_capital)) + 
  geom_bar(stat = "identity", position = "fill") +
  ylab("percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_is_capital_stacked.png"))

#############
# By gender
#############
by_gender <- agrar_full %>%
  filter(is_firm == 0) %>%
  select(year,amount,land_based,is_capital,gender)

ggplot(data = by_gender, aes(x = year, y = amount/1000000000, fill = gender)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_by_gender.png"))

ggplot(data = by_gender, aes(x = year, y = amount/1000000000, fill = gender)) + 
  geom_bar(stat = "identity", position = "fill") +
  ylab("percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal()
ggsave(paste0(data_out, "2d_sum_by_year_by_gender_stacked.png"))
rm(by_gender)


