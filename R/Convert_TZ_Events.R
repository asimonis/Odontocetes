#Convert PST to UTC times for PASCAL beaked whale events
#Required libraries
library(RSQLite)
library(dplyr)
library(PAMpal)
library(stringr)
library(lubridate)

#Directory with all databases
DBDir='H:/Odontocetes/Beaked whales/PASCAL_2016_Databases/'
setwd(DBDir)
DBFiles<-dir(DBDir,pattern='.sqlite3')

#Database route
sqlite <- dbDriver("SQLite")

#Create dataframe for all events
EventInfo<-data.frame()

#Extract event info from each database
for(dbInd in seq_along(DBFiles)){
  conn <- dbConnect(sqlite,DBFiles[dbInd])
  Events <- dbReadTable(conn, "Click_Detector_OfflineEvents")         #read offline events
  if(nrow(Events)==0){next}
  Events$eventType<-gsub(" ", "", Events$eventType, fixed = TRUE)
  Events$StartTime<-as.POSIXct(Events$UTC,format="%Y-%m-%d %H:%M:%OS", tz="America/Los_Angeles")
  Events$Start_UTC<-with_tz(Events$StartTime,tz="UTC")
  Events<-Events %>% 
   select(Id,eventType,nClicks,StartTime,Start_UTC)
  
  write.csv(Events,file=paste0(DBDir,substr(DBFiles[dbInd],1,10),'_BWEvents_UTC.csv')) 
  dbDisconnect(conn)
  }
