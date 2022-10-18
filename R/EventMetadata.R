#Create R data files for beaked whale events

#Required libraries
library(RSQLite)
library(dplyr)
library(PAMpal)
library(stringr)

Project<-'CCES'
speciesID<-c("ZC","BB","MS","BW43","BW37V","BWC","BW","?BW")
  
#Directory with all databases
DBDir='H:/CCES/CCES PAMGUARD Analyses 2_00_16/Databases/Final Databases_wGPS'
setwd(DBDir)
DBFiles<-dir(DBDir,pattern='.sqlite3')

#Database route
sqlite <- dbDriver("SQLite")

#Create dataframe for all events
EventInfo<-data.frame()

#Extract event info from each database
for(dbInd in seq_along(DBFiles)){
conn <- dbConnect(sqlite,DBFiles[dbInd])
GPS<-dbReadTable(conn,'gpsData')
GPS$dateTime<-as.POSIXct(GPS$UTC,format="%Y-%m-%d %H:%M:%OS", tz="UTC")

Events <- dbReadTable(conn, "Click_Detector_OfflineEvents")         #read offline events
Events$eventType<-gsub(" ", "", Events$eventType, fixed = TRUE)
Events<-filter(Events, eventType %in% speciesID)
Events$StartTime<-as.POSIXct(Events$UTC,format="%Y-%m-%d %H:%M:%OS", tz="UTC")
Events$EndTime<-as.POSIXct(Events$EventEnd,format="%Y-%m-%d %H:%M:%OS", tz="UTC")

Events<-select(Events,StartTime,EndTime,Id,UID,eventType,nClicks,minNumber,bestNumber,maxNumber)
Events<-rename(Events,species=eventType)

for(e in 1:nrow(Events)){
  TD<-as.numeric(difftime(Events$StartTime[e],GPS$dateTime,units="min"))
  GPSind<-which.min(abs(TD))
  Events$Latitude[e]<-GPS$Latitude[GPSind]
  Events$Longitude[e]<-GPS$Longitude[GPSind]}

Events$Project<-Project
Events$Deployment<-as.numeric(str_extract(DBFiles[dbInd], "(?i)(?<=Drift-)\\d+"))

dbDisconnect(conn)

#Aggregate into single dataframe
EventInfo<-rbind(EventInfo,Events)
}

save(EventInfo,file='CCES2018_BW_Detections.rda')
