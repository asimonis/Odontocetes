#Summarize detections for Data Nuggets
#Note - does not consider times with masking
#Anne Simonis


#Load Packages
if(!require('devtools')) install.packages('devtools')
# install from GitHub
devtools::install_github('TaikiSan21/PAMmisc')

library(here)
library(tidyverse)
library(xlsx)
library(PAMmisc)
library(stringr)
source("~/GitHub/Odontocetes/R/DataNugget_Functions.R")

# source('C:/Users/anne.simonis/Documents/GitHub/PAMmisc/devel/binDetectionFunctions.R')
# 
# #load GPS data needed for binning
# gps <- readRDS(here('data','AllDeploymentGPS.rds'))

PmHours<-HourlyBin(Species='Pm',detection_dir='C:/Users/anne.simonis/Documents/ADRIFT/Analysis/logs/Sperm whales','AdhocDetections')
DolphinHours<-HourlyBin(Species=c('Lo'),detection_dir='C:/Users/anne.simonis/Documents/ADRIFT/Analysis/logs/Dolphins/AA','Detections')
ShipHours<-HourlyBin(Species='Anthro',detection_dir='C:/Users/anne.simonis/Documents/ADRIFT/Analysis/logs/Sperm whales','AdhocDetections')

################################################################################

#Load metadata info into a single dataframe and only keep CCC drifts
metadata<-read.csv(here('data','Deployment Details.csv')) %>%
  filter(Project=='ADRIFT')%>%
  select(Drift.,Data_Start,Data_End,Cruise) %>%
  na.omit() %>%
  rename(Adrift.id=Drift.) %>%
  filter(Cruise =='CCC') %>%
  mutate(Data_Start_floor = floor_date(as.POSIXct(Data_Start,format='%m/%d/%Y %H:%M',tz='UTC'),unit = "hour"),
         Data_End_floor = floor_date(as.POSIXct(Data_End,format='%m/%d/%Y %H:%M',tz='UTC'),unit = "hour"))

metadata<-metadata %>%
  filter(Adrift.id %in% c('ADRIFT_020','ADRIFT_021','ADRIFT_023','ADRIFT_024','ADRIFT_025'))

#Create new dataframe with hourly observations
HourlyDFall<-data.frame(DateTime=seq.POSIXt(metadata$Data_Start_floor[1],metadata$Data_End_floor[1],by='hour'),
                        Adrift.id=metadata$Adrift.id[1])
for(d in 2:nrow(metadata)){
  HourlyDF<-data.frame(DateTime=seq.POSIXt(metadata$Data_Start_floor[d],metadata$Data_End_floor[d],by='hour'),
                       Adrift.id=metadata$Adrift.id[d])
  HourlyDFall<-rbind(HourlyDFall,HourlyDF)              
}

#Add species presence
PmHours<-PmHours %>%
  rename(Sperm_Whale=Sp_pres)

DolphinHours<-DolphinHours %>%
  rename(Pacific_white_sided_Dolphin=Sp_pres)

ShipHours<-ShipHours %>%
  rename(Ship=Sp_pres)

HourlyPres<-merge(PmHours,HourlyDFall,by=c('Adrift.id','DateTime'),all=TRUE)
HourlyPres<-merge(DolphinHours,HourlyPres,by=c('Adrift.id','DateTime'),all=TRUE)
HourlyPres<-merge(ShipHours,HourlyPres,by=c('Adrift.id','DateTime'),all=TRUE)
HourlyPres[is.na(HourlyPres)] <- 0
HourlyPres<-HourlyPres %>%
  rename(Adrift_id=Adrift.id)%>%
  mutate(Month=month(DateTime))%>%
  arrange(Adrift_id,DateTime,Pacific_white_sided_Dolphin,Sperm_Whale,Ship,Month)

############
PmSummary<-PmHours %>%
  group_by(Adrift.id)%>%
  filter(Sperm_Whale==1)%>%
  summarize(Pm_Hours=n())

DolphinSummary<-DolphinHours %>%
  group_by(Adrift.id)%>%
  filter(Pacific_white_sided_Dolphin==1)%>%
  summarize(Dolphin_Hours=n())

ShipSummary<-ShipHours %>%
  group_by(Adrift.id)%>%
  filter(Ship==1)%>%
  summarize(Ship_Hours=n())

DriftSummary<-HourlyPres %>%
  group_by(Adrift_id)%>%
  summarize(Total_hours=n())

Summary<-merge(PmSummary,DolphinSummary,by='Adrift.id',all=TRUE)
Summary<-merge(ShipSummary,Summary,by='Adrift.id',all=TRUE)
Summary[is.na(Summary)] <- 0

#############
#Save CSV file
write.csv(HourlyPres,
          file=here('data','DataNuggets_Odontocete+Ships_HourlyPresence.csv'),
          row.names=FALSE)

write.csv(Summary,
          file=here('data','DataNuggets_Odontocete+Ships_HourlySummary.csv'),
          row.names=FALSE)


