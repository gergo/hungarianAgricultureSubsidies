
install.packages("plyr")

# Libraries
library(plyr)
require(haven)
library(dplyr)
library(gridExtra)
library(cowplot)
library(grid)
library(lspline)
library(gridExtra)
#install.packages("ggstatsplot")
library(ggstatsplot)
library(scales)
library(grid)
library(RColorBrewer)

#### Check for all hotels registered in Vienna
ggplot(data = datau, aes(x = distance)) +
  geom_histogram(binwidth = 1.6, color = "black", fill = "blue", alpha = 0.8) +
  labs(x = "Distance to city center (km)", y = "Frequency") +
  theme_bg()
ggsave(paste0(output, "F07_notused1_R.png"))

# Check the actual cities
table(datau$city_actual)

# Double check on histogram
ggplot(data = subset(datau,city_actual=="Vienna"), aes(x = distance)) +
  geom_histogram(binwidth = 1.6, color = "black", fill = "blue", alpha = 0.8) +
  labs(x = "Distance to city center (km)", y = "Frequency") +
  theme_bg()
ggsave(paste0(output, "F07_notused2_R.png"))

# Filter non Vienna proper: drop hotels not really in Vienna
datau<-subset(datau,city_actual=="Vienna")

# save a copy of the work file
write.csv(datau, paste0(data_out,"hotels_work.csv"), row.names= F)


##########################
## PART II. Regressions ##

##
# SUMMARY STATISTICS ON PRICE AND DISTANCE



# Same with distance
distance <- hotels$distance
descr_disc <- as.matrix( c( mean(distance) , sd(distance), min(distance) , max(distance) , quantile(distance,.50), quantile(distance,.95) , length(distance)) )
dimnames(descr_disc)[[1]] <- list('mean','sd','min','max', 'p50' , 'p95' , 'n')
print(descr_disc)

# Remove objects
rm(descr_disc, descr_price, price, distance)

## Figure 2.1
## histogram of price and distance
ggplot(data = hotels, aes(x = price)) +
  geom_histogram(binwidth = 20, color = "black", fill = "blue", alpha = 0.8) +
  labs(x = "Hotel price (EUR)", y = "Frequency") +
  theme_bg()
ggsave(paste0(output, "F07_notused3_R.png"), width=10, height=7.5)


ggplot(data = hotels, aes(x = distance)) +
  geom_histogram(binwidth = 0.5, color = "black", fill = "blue", alpha = 0.8) +
  labs(x = "Distance to city center (km)", y = "Frequency") +
  theme_bg()
ggsave(paste0(output, "F07_notused4_R.png"), width=10, height=7.5)


#####################################
### REGRESSION 1: CLOSE VS FAR  #####
#  REGRESSION WITH BINARY DISTANCE  #
#   1st step to nonparametric reg   #

# First create a new variable, which is 1 if distance is larger than 2 km
hotels$dist2 <- as.numeric(hotels$distance>=2)
# Get the mean value of the prices conditional on dist2
dist2 <- aggregate(hotels$price, list(dist2=hotels$dist2), mean)
# Round up to 2 digits
dist2$avgprice2 <- round(as.numeric(dist2$x),digits = 2)
dist2 <- select(dist2,-x)

## Now for more information lets merge these two category to the original dataset!
# Add variable to the original dataset - now each hotels are categorized
hotels <- left_join( hotels , dist2 )

# Name the values as Far and Close in dist2 dataset
dist2$dist2[which(dist2$dist2 == 1 )] = "Far"
dist2$dist2[which(dist2$dist2 == 0 )] = "Close"
# Show the simplified version
print(dist2)
# Figure - mean prices for hotels "Far" and "Close" to city center
ggplot(data = dist2, aes(x = dist2, y = avgprice2), label=avgprice2) +
  geom_point(size = 5, shape = 23, fill = "blue", color = "black", alpha = 0.8) +
  geom_text(aes(label = round(avgprice2)), hjust = -0.5, vjust = 0) +
  coord_cartesian(ylim = c(0, 400)) +
  labs(x = "Distance to city center (categories)", y = "Average hotel price (EUR)")+
  theme_bg()+
  background_grid(major = "y", minor = "y", size.major = 0.2)
ggsave(paste0(output, "F07_1_R.png"), width=10, height=7.5)


## Now check for the extra information, contained by the dataset!
# For technical reasons lets use data.table format!
hotels <- data.table(hotels)
# And rename also in hotels
hotels$dist2[which(hotels$dist2 == 1 )] = "Far"
hotels$dist2[which(hotels$dist2 == 0 )] = "Close"
# With this format we can calculate summary statistics easily conditioned by Far and Close
hotels[ , .(mean_dist=mean(distance), sd_dist = sd(distance),
            min_dist = min(distance) , max_dist = max(distance),
            mean_price = mean(price) , sd_price = sd(price),
            min_price = min(price) , max_price = max(price),.N),
  by=.(dist2)]

# And we get the same plot, but now with more information in a boxplot
ggplot(data = hotels, aes(x = dist2, y = price)) +
  stat_boxplot(geom = 'errorbar', linetype = 1, width = 0.5) +
  geom_boxplot(outlier.shape = NA, fill = "blue", color = "black", fatten = 0, alpha = 0.8) +
  stat_summary(fun.y = median, geom = "point", size=4, shape = 23, fill="gray80", color="black", alpha = 0.9) +
  coord_cartesian(ylim = c(0, 300)) +
  labs(y = "Hotel price (EUR)") +
  theme_bg()
ggsave(paste0(output, "F07_notused5_R.png"), width=10, height=7.5)

# Drop objects
rm(dist2)

##########################################
### REGRESSION 2: 4 DISTANCE CATEGORIES ##
#  2nd step to nonparametric regression  #

# Create 4 category:
#   0.5 - closer than 1 km
#   1.5 - between 1-2 km
#   2.5 - between 2-3 km
#   3.5 - more than 3 km (dist is skewed -> round up from 3.7)
hotels$dist4 <- 0.5+ 1*as.numeric(hotels$distance>=1) + 1*as.numeric(hotels$distance>=2) + 2.5*as.numeric(hotels$distance>=3)
# Calculate the mean prices according to these categories
dist4 <- aggregate(hotels$price, list(dist4=hotels$dist4), mean)
# Save as avg price and round to 2 digits
dist4$avgprice4 <- round(as.numeric(dist4$x),digits=2)
# Remove the variable "x"
dist4 <- select(dist4,-x)
# Figure - scatter plot for the four category
ggplot(data = dist4, aes(x = dist4, y = avgprice4), label = avgprice4) +
  geom_point(size = 5, shape = 23, fill = "blue", color = "black", alpha = 0.8) +
  geom_text(aes(label = round(avgprice4)), hjust = -0.5, vjust = -0.5) +
  coord_cartesian(xlim = c(0, 7), ylim = c(0, 400)) +
  labs(x = "Distance to city center (km)",y = "Average hotel price (EUR)") +
  theme_bg() +
  background_grid(major = "y", minor = "y", size.major = 0.2) +
  scale_x_continuous(limits=c(0,7), breaks=c(1,3,5,7))
ggsave(paste0(output, "F07_2_R.png"), width=10, height=7.5)

## Again merge with the original dataset
hotels <- left_join( hotels , dist4 )
# And check some descriptives
hotels <- data.table(hotels)
hotels[,.(mean_dist=mean(distance), sd_dist = sd(distance),
          min_dist = min(distance) , max_dist = max(distance),
          mean_price = mean(price) , sd_price = sd(price),
          min_price = min(price) , max_price = max(price),.N)
  ,by=.(dist4)]

# Scatter plot with regression lines: First create scatter plot
p1 <- ggplot(data = hotels, aes(x = distance, y = price)) +
  geom_point(size = 2, fill = "blue", color = "blue", shape = 4, stroke = 2) +
  coord_cartesian(xlim = c(0, 7), ylim = c(0, 400)) +
  labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
  theme_bg() +
  scale_x_continuous(limits=c(0,7), breaks=0:7) +
  background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_notused6_R.png"), plot=p1, width=10, height=7.5)

p1

p1  +
  geom_line(data = dist4, aes(x = dist4, y = avgprice4), size = 1, color = "black") +
  geom_point(data = dist4, aes(x = dist4, y = avgprice4), size = 4, shape = 23, fill="black", color="black") +
  labs(x = "Distance to city center (km)", y = "Hotel price (EUR)") +
  theme_bg() +
  background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_3_R.png"), width=10, height=7.5)

# Drop objects
rm(dist4)



##########################################
### REGRESSION 3:   DISTANCE CATEGORIES ##
#  3rd step to nonparametric regression  #

# Create 10 Categories
hotels$dist8 <- ( 0.3 + 0.6*as.numeric(hotels$distance>=0.6)
+ 0.6*as.numeric(hotels$distance>=1.2)
+ 0.6*as.numeric(hotels$distance>=1.8)
+ 0.6*as.numeric(hotels$distance>=2.4)
+ 0.6*as.numeric(hotels$distance>=3)
+ 0.6*as.numeric(hotels$distance>=3.6)
+ 0.6*as.numeric(hotels$distance>=4.2)
+ 0.6*as.numeric(hotels$distance>=4.8)
+ 0.6*as.numeric(hotels$distance>=6) )
# Table and descriptives
hotels <- data.table(hotels)
hotels[,.(mean_dist=mean(distance), sd_dist = sd(distance),
min_dist = min(distance) , max_dist = max(distance),
mean_price = mean(price) , sd_price = sd(price),
min_price = min(price) , max_price = max(price),.N),by=.(dist8)]
# Create aggregated values
dist8 <- aggregate(hotels$price, list(dist8=hotels$dist8), mean)
dist8$Eprice_cat8 <- round(as.numeric(dist8$x),digits=3)
dist8<-select(dist8,-x)
# Add to large data
hotels<-left_join(hotels,dist8)
# Scatter plot with disjoint regression lines
p1 +
geom_line(data = dist8, aes(x = dist8, y= Eprice_cat8), size = 1, color = "black") +
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)")+
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_4_R.png"), width=10, height=7.5)

###############################
### REGRESSION 4:   LOWESS   ##
#          Comparison         #
p1  +
geom_smooth(method="loess", color="black", se = F, size = 1) +
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_5_R.png"), width=10, height=7.5)

##########################

##########################
### LINEAR REGRESSIONS  ##
##########################

regression <- lm(price ~ distance, data=hotels)
summary(regression)

####SCATTERPLOT + REGRESSION LINE
p_regr <- p1  +
geom_smooth(method = "lm", color = "black", se = F, size = 1) +
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_6_R.png"), plot=p_regr, width=10, height=7.5)
# Plot
p_regr

# PREDICTED VALUES & RESIDUALS OF LINEAR REGRESSION
hotels$predprice <- predict(regression)
hotels$e <- resid(regression)

### THE LINEAR REGRESSION GOES THROUGH THE AVERAGES
### SCATTERPLOT + REGRESSION LINE + LINES FOR AVERAGES
p_regr  +
geom_vline(xintercept = mean(hotels$distance),color = "black")+
geom_hline(yintercept = mean(hotels$price),color = "black")+
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_notused7_R.png"), width=10, height=7.5)


# Regression with annotation
p_regr +
geom_errorbar(data=subset(hotels, hotels$distance==1.5), aes(x=distance, ymin=mean(hotels$price), ymax=174.02), width=0.2, size=1, color="black") +
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
annotation_custom(grid.text("Residual", x=0.3,  y=0.38, gp=gpar(color="black", fontsize=12, fontface="bold"))) +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_7_R.png"), width=10, height=7.5)



# historgram of residuals
ggplot(data = hotels, aes(x = e, y = (..count..)/sum(..count..))) +
geom_histogram(binwidth = 20, fill = "blue", color = "black", alpha = 0.8) +
coord_cartesian(xlim = c(-100, 300)) +
labs(x = "Residuals", y = "Percent") +
scale_y_continuous(name = "Percent", labels = scales::percent, limits = c(0, 0.3)) +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_8_R.png"), width=10, height=7.5)


# hotels with most negative residuals
# (stored in a new data frame; check data frame)
bestdeals <- hotels%>% arrange(e)%>% head(5)
bestdeals[,c("hotel_id","price","e")]

## Linear Regression vs. Nonparametric
p_regr + geom_smooth(method="loess", color="red", se = F, size = 1) +
labs(x = "Distance to city center (km)",y = "Hotel price (EUR)") +
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)

#### LOG_LINEAR REGRESSIONS
hotels$ln_price<-log(hotels$price)

regression2 <- lm(ln_price ~ distance, data=hotels)
summary(regression2)

#### SCATTERPLOT + REGRESSION LINE
ggplot(data = hotels, aes(x = distance, y = ln_price)) +
geom_point(size = 2, fill = "blue", color = "blue", shape = 4, stroke = 2) +
geom_smooth(method="lm", colour="black", se=F)+
coord_cartesian(xlim = c(0, 7), ylim = c(3, 7)) +
scale_x_continuous(limits=c(0,7), breaks=0:7) +
labs(x = "Distance to city center (km)", y = "Hotel price in logs")+
theme_bg() +
background_grid(major = "y", minor="y", size.major = 0.2)
ggsave(paste0(output, "F07_notused8_R.png"), width=10, height=7.5)

# Compare with linear regression - which model fits better?
summary(regression)




library(data.table)
library(readxl)
library(tidyverse)
library(corrr)

# convert character type columns to number
drinks$beer_servings <- as.numeric(drinks$beer_servings)
drinks$wine_servings <- as.numeric(drinks$wine_servings)
drinks$spirit_servings <- as.numeric(drinks$spirit_servings)
drinks$total_litres_of_pure_alcohol <- as.numeric(drinks$total_litres_of_pure_alcohol)
as.factor()
raw_drinks[1:5,]
```

## Calculate total liters of pure alcohol

*<span style="color:blue">using the following information:</span>*

  - *<span style="color:blue">1 ounce = 0.0295 l</span>*
  - *<span style="color:blue">Beer serving: 12 ounces, 5% alcohol</span>*
  - *<span style="color:blue">Wine serving: 5 ounces, 12% alcohol</span>*
  - *<span style="color:blue">Spirit serving: 1.5 ounces 40% alcohol</span>*

  I convert everything to metric and extract the raw alcohol content using the provided proportions.

```{r include=FALSE}
# add constants
ounce_in_liter <- 0.0295

volume_per_serving_beer <- 12
volume_per_serving_wine <- 5
volume_per_serving_spirit <- 1.5

alcohol_content_beer <- 0.05
alcohol_content_wine <- 0.12
alcohol_content_spirit <- 0.4

# calculate pure alcohol consumption per drink type in ounce
drinks$alcohol_beer <- drinks$beer_servings * volume_per_serving_beer * alcohol_content_beer
drinks$alcohol_wine <- drinks$wine_servings * volume_per_serving_wine * alcohol_content_wine
drinks$alcohol_spirit <- drinks$spirit_servings * volume_per_serving_spirit * alcohol_content_spirit

# total pure alcohol consumption in liters
drinks$total_litres_of_pure_alcohol <-
(drinks$alcohol_beer +
drinks$alcohol_wine +
drinks$alcohol_spirit) *
ounce_in_liter

raw_life_expectancy <- fread('LifeExpectancy.csv')

# drop unused columns
life_expectancy <- raw_life_expectancy %>%
select(-c(CountryCode,
WorldBankIncomeGroupDisplay,
WorldBankIncomeGroupGroupCode,
GhoCode,
GhoDisplay,
PublishStateCode,
PublishStateDisplay,
YearCode,
RegionDisplay,
DisplayValue,
SexDisplay))

# only keep the most recent year for each country
# keep life expectancy for both sexes
life_expectancy <- life_expectancy %>%
rename(YearsToLive=Numeric,
Year=YearDisplay,
country=CountryDisplay) %>%
filter(SexCode == 'BTSX') %>%
select(-SexCode) %>%
group_by(country) %>%
slice(which.max(Year)) %>%
select(-Year)


drinks_by_country <- life_expectancy %>%
inner_join(drinks, by = 'country') %>%
select(c(country,
YearsToLive,
RegionCode,
total_litres_of_pure_alcohol)) %>%
rename(AlcoholConsumption=total_litres_of_pure_alcohol) %>%
drop_na() %>%
filter(RegionCode == 'EMR' | AlcoholConsumption > 0)

drinks_by_country_no_zeros <- drinks_by_country %>%
filter(AlcoholConsumption > 0)

rinks_by_country_no_zeros[1:5,]


## Calculate correlation between expected lifetime and total liters of pure alcohol

The correlation is `r cor(drinks_by_country$YearsToLive, drinks_by_country$AlcoholConsumption)`. It looks like countries with higher alcohol consumption per person have higher life expectancy.

ggplot(data = drinks_by_country, aes(x = AlcoholConsumption, y = YearsToLive)) +
geom_point() +
geom_smooth(method = "lm", se = FALSE) +
theme_minimal()

# If I look at trend regression lines by region I see the same pattern across the board. I am guessing alcohol is a luxury good. If people have access to more alcohol they probably have access to better health care and education, which - I think - would have strong correlation with life expectancy. It would be interesting to see the distribution of life expectancy and alcohol consumption within a single country. I am guessing that in most countries the most severe drinkers don't live too long.

ggplot(data = drinks_by_country, aes(x = AlcoholConsumption, y = YearsToLive, color = RegionCode)) +
geom_point() +
geom_smooth(method = "lm", se = FALSE) +
theme_minimal()

drinks_by_country_with_stats <- drinks_by_country %>%
inner_join(countries, by = 'country') %>%
ungroup()
dim(drinks_by_country_with_stats)

correlations <- drinks_by_country_with_stats %>%
select(c(YearsToLive,
AlcoholConsumption,
Population,
Area,
`Pop. Density`,
Coastline,
`Infant mortality`,
Phones,
Arable,
Other,
Birthrate,
Deathrate
)) %>%
correlate() %>%
focus(YearsToLive)


correlations %>%
arrange(desc(abs(YearsToLive))) %>%
filter(abs(YearsToLive)>0.3)
