#Extract HP sensitivity information from Inventory and DeploymentDetails worksheets

# library(xlsx)
library(dplyr)
library(here)


# DeployDetails<-read.xlsx('Deployment Details.xlsx',sheetIndex=3)
# Array<-read.xlsx('Inventory.xlsx',sheetName='Array',rowIndex=NULL)
# Sens<-read.xlsx('Inventory.xlsx',sheetName='Hydrophones',rowIndex=NULL)
DeployDetails<-read.csv(here('data','Deployment Details.csv'),header=TRUE)
Array<-read.csv(here('data','Inventory_array.csv'),header=TRUE)
Sens<-read.csv(here('data','Inventory_hydrophones.csv'),header=TRUE)

DepID<-'ADRIFT_023'

DepIDDetails<-DeployDetails %>% 
  filter(Data_ID==DepID) 

DepArray<-DepIDDetails$Array_name

DepHP<- Array %>%
  filter(Array_name ==DepArray)%>%
  # select(CH1..Hydrophone.SN,CH1.Hydrophone.Distance..m.,
  #        Ch2.Hydrophone.SN,CH2.Hydrophone.Distance..m.)%>%
  rename(CH1.HP = SensorNumber_1..hydrophone.serial.number., 
         CH2.HP = SensorNumber_2..hydrophone.serial.number.,
         CH1.Dist = HydrophoneDistance_1..m.,
         CH2.Dist = HydrophoneDistance_2..m.)

DepSN<-c(DepHP$CH1.HP,DepHP$CH2.HP)
Ind<-which(Sens$Serial.Number %in% DepSN)

DepSens<-Sens[Ind,]
DepSens<-select(DepSens,Model,Serial.Number,Hydrophone.Sensitivity.dB.re..1V.uPa)

Ch1Ind<-which(DepSens$Serial.Number==DepHP$CH1.HP)
Ch2Ind<-which(DepSens$Serial.Number==DepHP$CH2.HP)

DepHP$CH1.Sens<-DepSens$Hydrophone.Sensitivity.dB.re..1V.uPa[Ch1Ind]
DepHP$CH2.Sens<-DepSens$Hydrophone.Sensitivity.dB.re..1V.uPa[Ch2Ind]

# DepHP<-DepHP[,c(1,2,5,3,4,6)]
DepHP$CH1.Sens
DepHP$CH1.Dist

DepHP$CH2.Sens
DepHP$CH2.Dist
