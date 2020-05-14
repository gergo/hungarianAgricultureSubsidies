############################################################
#
# Hungarian Agricultural Subsidies Analysis
# Gergo Szekely
#
############################################################
# Data import
# Feature engineering
# Graph creation
############################################################

# CLEAR MEMORY
rm(list=ls())

# install missing packages
list.of.packages <-c("tidyverse",
                     "ggplot2",
                     "data.table",
                     "plot3D",
                     "viridis"
                     )


new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)>0) {install.packages(new.packages)}
lapply(list.of.packages, require, character.only = TRUE)

dir <- getwd()
data_in <- paste0(dir,"/../output/")
data_out <- paste0(dir,"/../imgs/")

agrar_funds <- readr::read_csv(paste0(data_in, "agrar_funds.csv"))
agrar_funds$fund_id <- as.integer(agrar_funds$fund_id)

agrar_wins <- readr::read_csv(paste0(data_in, "agrar_wins.csv"))
agrar_wins$winner_id <- as.integer(agrar_wins$winner_id)
agrar_wins$fund_id <- as.integer(agrar_wins$fund_id)

agrar_winners <- readr::read_csv(paste0(data_in, "agrar_winners.csv"))
agrar_winners$settlement_id <- as.integer(agrar_winners$settlement_id)
agrar_winners$winner_id <- as.integer(agrar_winners$winner_id)

agrar_settlements <- readr::read_csv(paste0(data_in, "agrar_settlements.csv"))
agrar_settlements$settlement_id <- as.integer(agrar_settlements$settlement_id)

agrar_funds$land_based <- as.factor(agrar_funds$land_based)
agrar_wins$year <- as.factor(agrar_wins$year)
agrar_funds$reason <- as.factor(agrar_funds$reason)
agrar_funds$program <- as.factor(agrar_funds$program)
agrar_funds$source <- as.factor(agrar_funds$source)
agrar_settlements$is_capital <- as.factor(agrar_settlements$is_capital)
agrar_settlements$is_capital <- recode(agrar_settlements$is_capital,
                                `1` = "Budapest",
                                `2` = "County capital",
                                `3` = "District capital",
                                `4` = "Village or Town")

agrar_winners$is_firm <- as.factor(agrar_winners$is_firm)
agrar_winners$gender <- as.factor(agrar_winners$gender)
agrar_settlements$settlement_type <- as.factor(agrar_settlements$settlement_type)


agrar_full <- agrar_wins %>%
  inner_join(agrar_winners, by = "winner_id") %>%
  inner_join(agrar_settlements, by = "settlement_id") %>%
  inner_join(agrar_funds, by = "fund_id")
  
rm(agrar_wins)
rm(agrar_winners)
rm(agrar_funds)
rm(agrar_settlements)



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
  
##################################
# Yearly distribution of amounts
##################################
distinct_years <- full_by_year %>%
  select(year) %>%
  distinct()

save_3d_chart <- function(data, bins, target_var, dataset) {
  years <- dim(distinct_years)[1]

  chart_data <- data %>%
    group_by(year) %>%
    mutate(amount = amount/1000000) %>%
    mutate(rank = ntile(amount,bins)) %>%
    group_by(year,rank) %>%
    summarise(cnt=n(),
              log_avg=log(mean(amount)),
              avg=mean(amount),
              log_sum=log(sum(amount)),
              sum=sum(amount)) %>%
    arrange(desc(year)) %>%
    reshape2::dcast(rank ~ year, value.var = target_var) %>%
    column_to_rownames(var = "rank") %>%
    as.matrix()
  
  hist3D(x = 1:bins, y = 1:years, z = chart_data,
         bty = "g", phi = 20, theta = -60,
         main = paste0(dataset, " - ", bins, " bins - ", target_var, " (HUF mm)"),
         xlab = "bins", ylab = "years", zlab = target_var,
         border = "black", shade = 0.3, expand = 0.9, contour = TRUE,
         col=ramp.col(c("blue", "yellow", "red")),
         space = 0.25, d = 3,
         colkey = list(side = 4, length = 0.6, width = 0.5, dist = -0.04),
         axes = TRUE
         )
  
  # save image
  png(filename=paste0(data_out, "3d_",dataset,"_",target_var,"_",bins,".png"))
  plotdev()
  dev.off()
}


###################
# all amounts
###################
save_3d_chart(full_by_year, 10, "log_avg", "all_yearly")
save_3d_chart(full_by_year, 10, "avg", "all_yearly")
save_3d_chart(full_by_year, 10, "sum", "all_yearly")

rm(full_by_year)

###################
# sum_by_address
###################
sum_by_address <- agrar_full %>%
  select(year,zip,address,amount) %>%
  mutate(year = as.factor(year)) %>%
  group_by(year,zip,address) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address, 10, "avg", "summed-by-address")
save_3d_chart(sum_by_address, 30, "avg", "summed-by-address")
save_3d_chart(sum_by_address, 10, "log_avg", "summed-by-address")
save_3d_chart(sum_by_address, 30, "log_avg", "summed-by-address")
save_3d_chart(sum_by_address, 10, "sum", "summed-by-address")
save_3d_chart(sum_by_address, 30, "sum", "summed-by-address")
save_3d_chart(sum_by_address, 10, "log_sum", "summed-by-address")
save_3d_chart(sum_by_address, 30, "log_sum", "summed-by-address")

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
  labs(y = "sum amount (HUF bn)") +
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

###################################
# sum_by_address - individuals
###################################
sum_by_address_indiv <- agrar_full %>%
  filter(is_firm == 0) %>% 
  select(year,zip,address,amount) %>%
  mutate(year = as.factor(year)) %>%
  group_by(year,zip,address) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address_indiv, 10, "avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv, 10, "log_avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv, 10, "sum", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv, 10, "log_sum", "summed-by-address-indiv")

sum_by_address_indiv_decils <- sum_by_address_indiv %>%
  group_by(year) %>%
  mutate(rank = ntile(amount,10)) %>%
  mutate(rank = as.factor(rank)) %>%
  mutate(rank = fct_reorder(rank, desc(rank))) %>%
  group_by(year,rank) %>%
  summarise(sum=sum(amount)) %>%
  arrange(desc(year))

ggplot(data = sum_by_address_indiv_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (HUF bn)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme(axis.text.y = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_indiv.png"))

ggplot(data = sum_by_address_indiv_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "Pct of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_indiv_stacked.png"))

rm(sum_by_address_indiv)
rm(sum_by_address_indiv_decils)

###################################
# sum_by_address - individuals
###################################

sum_by_address_indiv_land <- agrar_full %>%
  filter(is_firm == 0, land_based == 1) %>% 
  select(year,zip,address,amount) %>%
  mutate(year = as.factor(year)) %>%
  group_by(year,zip,address) %>%
  summarise(amount=sum(amount))

save_3d_chart(sum_by_address_indiv_land, 10, "avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "log_avg", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "sum", "summed-by-address-indiv")
save_3d_chart(sum_by_address_indiv_land, 10, "log_sum", "summed-by-address-indiv")

sum_by_address_indiv_land_decils <- sum_by_address_indiv_land %>%
  group_by(year) %>%
  mutate(rank = ntile(amount,10)) %>%
  mutate(rank = as.factor(rank)) %>%
  mutate(rank = fct_reorder(rank, desc(rank))) %>%
  group_by(year,rank) %>%
  summarise(sum=sum(amount)) %>%
  arrange(desc(year))

ggplot(data = sum_by_address_indiv_land_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (HUF bn)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme(axis.text.y = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_indiv_land.png"))

ggplot(data = sum_by_address_indiv_land_decils, aes(x = year, y = sum/1000000000, fill = rank)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "Pct of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_indiv_land_stacked.png"))

rm(sum_by_address_indiv_land)
rm(sum_by_address_indiv_land_decils)

#########################
# 2D charts
#########################
sum_by_dummies <- agrar_full %>%
  select(amount,year,is_firm,land_based,is_capital,source) %>%
  mutate(year = as.factor(year)) %>%
  group_by(year,is_firm,land_based,is_capital,source) %>%
  summarise(amount=sum(amount))


ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = is_firm)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_isfirm.png"))

ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = is_firm)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_isfirm_stacked.png"))


ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = land_based)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_land_based.png"))

ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = land_based)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_land_based_stacked.png"))


ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = is_capital)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_is_capital.png"))

ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = is_capital)) + 
  geom_bar(stat = "identity", position = 'fill') +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_is_capital_stacked.png"))


ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = source)) + 
  geom_bar(stat = "identity") +
  ylab("sum of total amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_source.png"))

ggplot(data = sum_by_dummies, aes(x = year, y = amount/1000000000, fill = source)) + 
  geom_bar(stat = "identity", position = 'fill') +
  ylab("sum of total amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_source_stacked.png"))

rm(sum_by_dummies)

#############
# By gender
#############
by_gender <- agrar_full %>%
  filter(is_firm == 0) %>%
  select(year,amount,land_based,is_capital,gender) %>%
  mutate(year = as.factor(year)) %>%
  group_by(year,land_based,is_capital,gender) %>%
  summarise(amount=sum(amount))

ggplot(data = by_gender, aes(x = year, y = amount/1000000000, fill = gender)) + 
  geom_bar(stat = "identity") +
  labs(y = "sum amount (bn HUF)") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_gender.png"))

ggplot(data = by_gender, aes(x = year, y = amount/1000000000, fill = gender)) + 
  geom_bar(stat = "identity", position = "fill") +
  ylab("percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_sum_by_gender_stacked.png"))
rm(by_gender)

############################
# land-based trends
############################
full_by_year_by_type <- agrar_full %>%
  filter(land_based == 1) %>%
  select(amount,year,reason) %>%
  group_by(year,reason) %>%
  summarise(amount=sum(amount)) %>%
  as.data.frame()

ggplot(data = full_by_year_by_type, aes(x = year, y = amount/1000000000, fill = reason)) + 
  geom_bar(stat = "identity") +
  ylab("percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_land_based_trends.png"))

ggplot(data = full_by_year_by_type, aes(x = year, y = amount/1000000000, fill = reason)) + 
  geom_bar(stat = "identity", position = "fill") +
  ylab("percent of total amount") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
  theme_minimal() +
  scale_fill_viridis(discrete=TRUE,direction=1,option = "D")
ggsave(paste0(data_out, "2d_land_based_trends_stacked.png"))

rm(full_by_year_by_type)  
