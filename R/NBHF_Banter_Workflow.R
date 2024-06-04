


library(PAMpal)
library(dplyr)
library(banter)
library(densityClust)
library(purrr)
library(stringr)
library(tibble)
library(rfPermute)
library(tidyr)
library(sjPlot)

source('C:/Users/anne.simonis/Documents/GitHub/identidrift/R/make-model.R')
source('C:/Users/anne.simonis/Documents/GitHub/identidrift/R/make-study.R')

freshRun = FALSE

if(freshRun==TRUE){
#Generate Acoustic Study
dbFolder<-'H:/Odontocetes/NBHF/Labeled Events/Databases'
binFolder<-'H:/Odontocetes/NBHF/Binaries'
  # dbFolder<-'/Volumes/ADRIFT_Analysis/Odontocetes/NBHF/Labeled Events/Databases/'
  # binFolder<-'/Volumes/ADRIFT_Analysis/Odontocetes/NBHF/Binaries/'
  # 
#Add GPS to databases
# gpsFolder<-'/Users/ASimonis/Documents/ADRIFT Analysis/GPS_CSV'
gpsFolder<-'H:/GPS Files/GPS_CSV'
dbFiles<-list.files(path=dbFolder,pattern='.sqlite3',full.names = TRUE)
gpsFiles<-list.files(path=gpsFolder,pattern='.csv',full.names=TRUE)

dbDep<- str_extract(dbFiles,'ADRIFT_\\d{3}')
gpsDep<-str_extract(gpsFiles,'ADRIFT_\\d{3}')

for(d in 1:length(dbFiles)){
  gpsInd<-which(gpsDep==dbDep[d])
  addPgGps(dbFiles[d],gpsFiles[gpsInd],source='csv')
}
ADRIFT_NBHF<-addGps(ADRIFT_NBHF)

pps <- PAMpalSettings(dbFolder, binFolder, sr_hz='auto', filterfrom_khz=100, filterto_khz=160, winLen_sec=.0025)
ADRIFT_NBHF <- processPgDetections(pps, mode='db')
ADRIFT_NBHF <- setSpecies(ADRIFT_NBHF , method = 'pamguard')
# new "FP" and "TP" events in addition to originals
table(species(ADRIFT_NBHF))

#Only keep NBHF events from Ch 2
ADRIFT_NBHF<-filter(ADRIFT_NBHF, species=='NBHF',Channel==2)
ADRIFT_NBHF<-calculateICI(ADRIFT_NBHF,time='UTC')

#Remove duplicate events
ADRIFT_NBHF<-rm_dup_evs(ADRIFT_NBHF)

saveRDS(ADRIFT_NBHF, 'H:/Odontocetes/NBHF/Labeled Events/AcousticStudy_NBHF_ADRIFT_wGPS_wICI.rds')}else{
  ADRIFT_NBHF<-readRDS('H:/Odontocetes/NBHF/Labeled Events/AcousticStudy_NBHF_ADRIFT_wGPS_wICI.rds')
}

#Export to Banter and leave out false positives
NBHFdf<-export_banter(ADRIFT_NBHF,dropSpecies = 'FP')

#Assign new click detectors (hirange >125 kHz & lorange < 125 kHz)
#Use Jackson's function 'splitcalls' from identidrift repo 
NBHFdf<-split_calls(NBHFdf)

#Load Banter Model
bant<-readRDS('H:/Odontocetes/NBHF/BANTER/bant_VFB_2024May10.rds')

#Load Training Dataset
load("~/GitHub/identidrift/data/train.rda")

#Create summary table of training data
#Columns: Species, Number of Events, Median clicks per event (IQR)
ClicksKs<-getClickData(train$ks)
ClicksPd<-getClickData(train$pd)
ClicksPp<-getClickData(train$pp)

SumKs<-ClicksKs %>%
  group_by(eventId) %>%
  reframe(NClicks = length(peak)) %>%
  reframe(NEvents=length(unique(eventId)),
          MedClicks = paste0(median(NClicks),' (',round(quantile(NClicks,c(.25))),'-',round(quantile(NClicks,c(.75))),')'),
          TotClicks=sum(NClicks))%>%
  mutate(Species='Ks')

SumPd<-ClicksPd %>%
  group_by(eventId) %>%
  reframe(NClicks = length(peak)) %>%
  reframe(NEvents=length(unique(eventId)),
          MedClicks = paste0(median(NClicks),' (',round(quantile(NClicks,c(.25))),'-',round(quantile(NClicks,c(.75))),')'),
          TotClicks=sum(NClicks))%>%
  mutate(Species='Pd')

SumPp<-ClicksPp %>%
  group_by(eventId) %>%
  reframe(NClicks = length(peak)) %>%
  reframe(NEvents=length(unique(eventId)),
          MedClicks = paste0(median(NClicks),' (',round(quantile(NClicks,c(.25))),'-',round(quantile(NClicks,c(.75))),')'),
          TotClicks=sum(NClicks)) %>%
  mutate(Species='Pp')


TrainTable<-rbind(SumKs,SumPd,SumPp)
TrainTable <- TrainTable[, c("Species", "NEvents", "MedClicks","TotClicks")]

ColHeaders <-c('Species','N Events','Event Clicks','Total Clicks')


tab_df(TrainTable,alternate.rows=T,
       title="Summary of NBHF training dataset, including acoustic events with
       visually-verified species identification for Kogia (Ks), Dall's porpoise 
       (Pd), and harbor porpoise (Pp)). Reported values include the total number 
       of acoustic events (N Events), median number of clicks per event, with the
       inter-quartile range in parenthesis, and the total number of clicks 
       (Total Clicks) for each species.",col.header = ColHeaders)




plotPredictedProbs(bant.rf, bins = 30, plot = TRUE)

NBHFpredict<-predict(bant,NBHFdf)
