


library(PAMpal)
library(dplyr)
library(banter)
library(densityClust)
library(purrr)
library(stringr)
library(tibble)
library(rfPermute)
library(tidyr)

source('C:/Users/anne.simonis/Documents/GitHub/identidrift/R/make-model.R')
source('C:/Users/anne.simonis/Documents/GitHub/identidrift/R/make-study.R')

freshRun = FALSE

if(freshRun==TRUE){
#Generate Acoustic Study
dbFolder<-'H:/Odontocetes/NBHF/Labeled Events/Databases'
binFolder<-'H:/Odontocetes/NBHF/Binaries'

pps <- PAMpalSettings(dbFolder, binFolder, sr_hz='auto', filterfrom_khz=100, filterto_khz=160, winLen_sec=.0025)
ADRIFT_NBHF <- processPgDetections(pps, mode='db')
ADRIFT_NBHF <- setSpecies(ADRIFT_NBHF , method = 'pamguard')
# new "FP" and "TP" events in addition to originals
table(species(ADRIFT_NBHF))

saveRDS(ADRIFT_NBHF, 'H:/Odontocetes/NBHF/Labeled Events/AcousticStudy_NBHF_ADRIFT.rds')}else{
  ADRIFT_NBHF<-readRDS('H:/Odontocetes/NBHF/Labeled Events/AcousticStudy_NBHF_ADRIFT.rds')
}

#Only keep NBHF events from Ch 2
ADRIFT_NBHF<-filter(ADRIFT_NBHF, species=='NBHF',Channel==2)
ADRIFT_NBHF<-calculateICI(ADRIFT_NBHF,time='UTC')

#Remove duplicate events
ADRIFT_NBHF<-rm_dup_evs(ADRIFT_NBHF)

#Export to Banter and leave out false positives
NBHFdf<-export_banter(ADRIFT_NBHF,dropSpecies = 'FP')

#Assign new click detectors (hirange >125 kHz & lorange < 125 kHz)
#Use Jackson's function 'splitcalls' from identidrift repo 
NBHFdf<-split_calls(NBHFdf)

#Load Banter Model
bant<-readRDS('H:/Odontocetes/NBHF/BANTER/bant_VFB_2024May10.rds')
bant.rf <- getBanterModel(bant)

plotPredictedProbs(bant.rf, bins = 30, plot = TRUE)

NBHFpredict<-predict(bant,NBHFdf)
