## Script for downloading the bike data

library(lubridate)
library(stringr)
library(dplyr)
library(tidyr)


path <- "data/bike/"
suffix <- "-capitalbikeshare-tripdata.zip"

# Creating the filenames
prefix <- seq(ym("2018-01"), ym("2020-12"), by = "months")
years <- year(prefix)
months <- str_pad(month(prefix),2,pad="0")
monthly_prefix <- paste0(years,months)

zip_files <- paste0(monthly_prefix,suffix)
base_url <- "https://s3.amazonaws.com/capitalbikeshare-data/"

#Website doesn't have April 2020 data
to_drop <- which(zip_files==paste0("202004",suffix)) 
zip_files <- zip_files[-to_drop]

# This process might take a little while
for (file in zip_files){
  download.file(url = paste0(base_url,file),
                destfile = paste0(path,file))
  unzip(paste0(path,file),exdir=path)
}

files <- list.files(path=path,pattern="*.csv")

# Generating first dataset with first csv file
bike_data <- read.csv(paste0(path,files[1]),header=TRUE,stringsAsFactors=FALSE,fileEncoding="latin1")

bike_data <- bike_data %>% mutate(date_time=ymd_h(substr(Start.date,1,13))) %>% 
  filter(Member.type %in% c("Member","Casual")) %>% 
  mutate(dummy = 1) %>% 
  spread(Member.type, dummy, fill = 0) %>% 
  select(date_time,Casual,Member) %>% 
  group_by(date_time) %>% 
  summarise(Casual=sum(Casual),
            Member=sum(Member))


# Looping over the other files and merging with first one
  
k = which(substr(files,1,6)=="202005") 
for (i in 2:length(files)){
  data_i <- read.csv(paste0(path,files[i]),header=TRUE,stringsAsFactors=FALSE,fileEncoding="latin1")
  if (i<k){
    data_i <- data_i %>% mutate(date_time=ymd_h(substr(Start.date,1,13))) %>% 
      filter(Member.type %in% c("Member","Casual")) %>% 
      mutate(Member.Type = tolower(Member.Type),dummy = 1) %>% 
      spread(Member.type, dummy, fill = 0)
  }
  else{ #After k, the columns changes
    data_i <- data_i %>% mutate(date_time=ymd_h(substr(started_at,1,13))) %>% 
      filter(member_casual %in% c("member","casual")) %>% 
      mutate(dummy = 1) %>% 
      spread(member_casual, dummy, fill = 0)
  }
   data_i <- data_i  %>% 
    select(date_time,casual,member) %>% 
    group_by(date_time) %>% 
    summarise(Casual=sum(casual),
              Member=sum(member))
  bike_data <- rbind(bike_data,data_i)
  print(paste("Loop",i,"/",length(files),"completed sucessfully"))
  rm(data_i)
}

save(bike_data,file=paste0(path,"bike_data.rda"))
save(bike_data,file=paste0(path,"bike_data.csv"))
