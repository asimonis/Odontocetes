#Compare Events defined by analysts (AES & JMT) with 
#Jay's Matched Template Classifier threshold method ('MakePamGuardEventsFromTemplateClassifer v5.r')
#Output precision & recall for each species 

library(lubridate)
library(RSQLite)
library(dplyr)

sqlite <- dbDriver("SQLite")
DBDir<-"D:/CCES/CCES PAMGUARD Analyses 2_00_16/Drift-20 - Copy/12 dB threshold/"
DataBase= "PamGuard64 2_00_16e Drift-20_JST.sqlite3"

TemplNames=c("ZC","BW43","BW39V","MS","BB","BW70")

#Load in Event Info from Database 
conn <- dbConnect(sqlite,file.path(DBDir,DataBase))
Events <- dbReadTable(conn, "Click_Detector_OfflineEvents")         #read offline events
Events$eventType<-gsub(" ", "", Events$eventType, fixed = TRUE)
Events$dateTime<-strptime(Events$UTC,format="%Y-%m-%d %H:%M:%OS")
Events$dateTime<-as.POSIXct(Events$dateTime, tz="UTC")

TP<-numeric()
FP<-numeric()
FN<-numeric()
Precision<-numeric()
Recall<-numeric()

for(t in 1:length(TemplNames)){
#Define "ground truth" from original analysis
GTdf<-filter(Events,eventType==TemplNames[t])

#Define detections identified by MTC
MTCdf<-filter(Events,eventType==t)

#Define true positive (TP). Consider TP if ground truth event starts within 2 minutes of MTC time 
MTCdf$match<-FALSE
for(i in 1:nrow(MTCdf)){
 Ind<-which(GTdf$dateTime>=(MTCdf$dateTime[i]-minutes(2)) & GTdf$dateTime<=(MTCdf$dateTime[i]+minutes(2)))
 if(length(Ind)>0){MTCdf$match[i]<-TRUE}
}

TP[t]<-length(which(MTCdf$match==TRUE))

#Define false positives
FP[t]<-length(which(MTCdf$match==FALSE))
  
#Define false negative (missed)
FN[t]<-nrow(GTdf)-TP[t]

#Precision
Precision[t]<-TP[t] / nrow(MTCdf)

#Recall
Recall[t]<- TP[t] / (TP[t] + FN[t])
  
}

DF<-data.frame(Species=TemplNames,TP,FP,FN,Precision,Recall)


