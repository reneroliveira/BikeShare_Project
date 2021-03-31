## Script for downloading the climate data
library(rnoaa)
library(dplyr)
library(lubridate)

# Washington DC station codes from "ftp://ftp.ncdc.noaa.gov/pub/data/noaa/isd-history.txt"
usaf <- "724050";wban <- "13743" 
raw2020 <- isd(usaf=usaf, wban=wban, year=2020,parallel = TRUE,cores = 3)
raw2019 <- isd(usaf=usaf, wban=wban, year=2019,parallel = TRUE,cores = 3)
raw2018 <- isd(usaf=usaf, wban=wban, year=2018,parallel = TRUE,cores = 3)

# Selecting columns
raw2018 <- raw2018 %>% select(date,time,temperature)
raw2019 <- raw2019 %>% select(date,time,temperature)
raw2020 <- raw2020 %>% select(date,time,temperature)
raw <- rbind(raw2018,raw2019,raw2020)

# Parsing dates
raw$date_time <- ymd_h(
  sprintf("%s %s", as.character(raw$date), substr(raw$time,1,2))
)
raw$temperature <- as.numeric(raw$temperature)

# Agreggating by hourly mean
hourly_temp <- raw %>% filter(temperature < 900) %>% 
  mutate(temperature=temperature/10) %>% 
  group_by(date_time) %>% 
  summarise(temperature = mean(temperature)) %>% 
  select(date_time,temperature)

# Saving the file
save(hourly_temp,file="data/hourly_temp.rda")
save(hourly_temp,file="data/hourly_temp.csv")
