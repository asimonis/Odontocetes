#Summarize detections for Data Nuggets
#Note - does not consider times with masking
#Anne Simonis


#Load Packages
if(!require('devtools')) install.packages('devtools')
# install from GitHub
devtools::install_github('TaikiSan21/PAMmisc')

library(here)
library(tidyverse)
library(lubridate)
library(ggplot2)
library(xlsx)
library(PAMmisc)
library(stringr)
source(here('R','reportPlotFunctions.R'))

#Define data to include
CCCdrifts<-c(paste0('ADRIFT_0',c(19:26,46:53,79:84)),paste0('ADRIFT_',101:108))

#Read GPS data
gps <- readRDS('C:/Users/anne.simonis/Documents/GitHub/Odontocetes/data/AllDeploymentGPS.rds')
gps<-gps %>% 
  filter(DriftName %in% CCCdrifts)

#Import and format detections by species
#Species
logFolder <- 'C:/Users/anne.simonis/Documents/ADRIFT/Analysis/logs/Dolphins/AA/'
logFiles <- list.files(logFolder, full.names=TRUE)
detData <- loadDetectionData(logFiles, source='triton',sheet='Detections')

DolphinData<-detData %>%
  filter(DriftName %in% CCCdrifts, species=="Lo")

binnedDolphin <- formatBinnedPresence(DolphinData, bin='hour', gps=gps)
binnedDolphin$Dolphin<-ifelse(is.na(binnedDolphin$species),0,1)

binnedDolphin<-binnedDolphin %>%
  select(UTC,DriftName,Dolphin) %>%
  rename(DateTime = UTC, 
         Adrift_id=DriftName,
         Pacific_white_sided_dolphin=Dolphin)
binnedDolphin<-unique(binnedDolphin)

SummaryDolphin<-binnedDolphin %>%
  group_by(Adrift_id)%>%
  summarize(Pacific_white_sided_dolphin_detection=sum(Pacific_white_sided_dolphin))

####
#Sperm whales
logFolder <- 'C:/Users/anne.simonis/Documents/ADRIFT/Analysis/logs/CCC_Pm/'
logFiles <- list.files(logFolder, full.names=TRUE)
detData <- loadDetectionData(logFiles, source='triton',sheet='Detections')

PmData<-detData%>% 
  filter(DriftName %in% CCCdrifts, species=="Pm")

binnedPm <- formatBinnedPresence(PmData, bin='hour', gps=gps)
binnedPm$Sperm_whale<-ifelse(is.na(binnedPm$species),0,1)

binnedPm<-binnedPm %>%
  select(UTC,DriftName,Sperm_whale) %>%
  rename(DateTime = UTC, Adrift_id=DriftName)
binnedPm<-unique(binnedPm)

SummaryPm<-binnedPm %>%
  group_by(Adrift_id)%>%
  summarize(Sperm_whale_detection=sum(Sperm_whale))

#Ships
ShipData<-detData%>% 
  filter(DriftName %in% CCCdrifts, species=="Anthro")
binnedShip<- formatBinnedPresence(ShipData, bin='hour', gps=gps)
binnedShip$Ship<-ifelse(is.na(binnedShip$species),0,1)

binnedShip<-binnedShip %>%
  select(UTC,DriftName,Ship) %>%
  rename(DateTime = UTC, Adrift_id=DriftName) 
binnedShip<-unique(binnedShip)

SummaryShip<-binnedShip %>%
  group_by(Adrift_id)%>%
  summarize(Ship_detection=sum(Ship))

#Hourly Presence
HourlyPresence<-merge(binnedDolphin,binnedPm,by=c("Adrift_id","DateTime"))
HourlyPresence<-merge(HourlyPresence,binnedShip,by=c("Adrift_id","DateTime"))

#Hourly Summary
HourlySum<-merge(SummaryDolphin,SummaryPm,by='Adrift_id') 
HourlySum<-merge(HourlySum,SummaryShip,by='Adrift_id')


#############
#Save CSV file
write.csv(HourlyPresence,
          file=here('data','DataNuggets_Odontocete+Ships_HourlyPresence.csv'),
          row.names=FALSE)

write.csv(HourlySum,
          file=here('data','DataNuggets_Odontocete+Ships_HourlySummary.csv'),
          row.names=FALSE)


