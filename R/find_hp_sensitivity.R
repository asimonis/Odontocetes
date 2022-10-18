#Extract HP sensitivity information from Inventory and DeploymentDetails worksheets

library(xlsx)
library(dplyr)


setwd('C:/Users/anne.simonis.NMFS/Documents/ADRIFT')
DeployDetails<-read.xlsx('Deployment Details.xlsx',sheetIndex=3)
Array<-read.xlsx('Inventory.xlsx',sheetName='Array',rowIndex=NULL)
Sens<-read.xlsx('Inventory.xlsx',sheetName='Hydrophones',rowIndex=NULL)

DepID<-'ADRIFT_013'

DepIDDetails<-DeployDetails %>% 
  filter(Data_ID==DepID) 

DepArray<-DepIDDetails$Array_name

DepHP<- Array %>%
  filter(Array. ==DepArray)%>%
  select(CH1..Hydrophone.SN,CH1.Hydrophone.Distance..m.,
         Ch2.Hydrophone.SN,CH2.Hydrophone.Distance..m.)%>%
  rename(CH1.HP = CH1..Hydrophone.SN, 
         CH2.HP = Ch2.Hydrophone.SN,
         CH1.Dist = CH1.Hydrophone.Distance..m.,
         CH2.Dist = CH2.Hydrophone.Distance..m.)

DepSN<-c(DepHP$CH1.HP,DepHP$CH2.HP)
Ind<-which(Sens$Serial.Number %in% DepSN)

DepSens<-Sens[Ind,]
DepSens<-select(DepSens,Model,Serial.Number,Hydrophone.Sensitivity.dB.re..1V.uPa)

Ch1Ind<-which(DepSens$Serial.Number==DepHP$CH1.HP)
Ch2Ind<-which(DepSens$Serial.Number==DepHP$CH2.HP)

DepHP$CH1.Sens<-DepSens$Hydrophone.Sensitivity.dB.re..1V.uPa[Ch1Ind]
DepHP$CH2.Sens<-DepSens$Hydrophone.Sensitivity.dB.re..1V.uPa[Ch2Ind]

DepHP<-DepHP[,c(1,2,5,3,4,6)]
DepHP
