# Make new events from PamGuard binaries using ClickTemplate values
# This version uses the Match correlation value (not the correlation difference)

library(PAMmisc)    #package 'PamBinaries' requires R >=  3.4.0
library(PamBinaries)
library(dplyr)
library(RSQLite)

#Define folder with binaries and database
folder= "D:/CCES/CCES PAMGUARD Analyses 2_00_16/Drift-20 - Copy/12 dB threshold/"
setwd(folder)

# Read dataframe created from PamGuard Binaries (if not in Environment)
MasterClickDF= read.csv("ClickBinaries.csv")

# Input names for respective templates in dataframe
TemplNames=c("Zc","BW43","BW39V","Ms","Bb","BW70")
numTemplates= length(TemplNames)
TemplNames= paste(TemplNames,"_match",sep="") # use the Match Correlation values
DataBase= "PamGuard64 2_00_16e Drift-20_JST.sqlite3"
TemplThresh1= rep(NA,numTemplates)
TemplThresh2= rep(NA,numTemplates)
MatchCol= array()

# identify clicks in that dataframe with template classification values above threshhold-1
MasterClickDF$AboveThresh1= FALSE
MasterClickDF$AboveThresh2= FALSE
for (iTempl in 1:numTemplates) {
  iCol= which(names(MasterClickDF)==TemplNames[iTempl])  #find the column corresponding to the match score for given template
  MatchCol[iTempl]= iCol
  TemplThresh1[iTempl]= quantile(MasterClickDF[,iCol],probs=0.975,na.rm=T)
  TemplThresh2[iTempl]= quantile(MasterClickDF[,iCol],probs=0.999,na.rm=T)
  MasterClickDF$AboveThresh1= MasterClickDF$AboveThresh1 | (MasterClickDF[,iCol]>TemplThresh1[iTempl])
  MasterClickDF$AboveThresh2= MasterClickDF$AboveThresh2 | (MasterClickDF[,iCol]>TemplThresh2[iTempl])
}
TemplThresh1
TemplThresh2

# subset all clicks to include only those with at least one template above threshhold and mean amplitude
#MeanAmpl= mean(MasterClickDF$)
TemplClickDF=MasterClickDF[MasterClickDF$AboveThresh1,]
# convert time to R format and eliminate missing times
TemplClickDF$UTCdatetime= as.POSIXct(TemplClickDF$date, origin = "1970-01-01", tz = "UTC")
TemplClickDF= TemplClickDF[!is.na(TemplClickDF$UTCdatetime),]

# if angles are present, convert to degress 
if (sum(!is.na(TemplClickDF$angles)) > 1) {
  AnglesTF= TRUE
  TemplClickDF$angleDeg= TemplClickDF$angles * 180 / pi
} else {
  AnglesTF= FALSE
}


# create events from all clicks of a given class within iMin minutes 
#   and iDeg of clicks that are above Threshhold-2
nEvents= 0
iMin= 10
iDeg= 2
#
# create events for each binary file with values over TemplThresh2
  BinaryFiles= sort(unique(TemplClickDF$BinaryFile))
  BinaryFile= BinaryFiles[1]
  for (BinaryFile in BinaryFiles) {
    
    #subset clicks in given binary over threshold 1
    Subset1= TemplClickDF[(TemplClickDF$BinaryFile==BinaryFile),]
    Subset1$BestMatch= NA
    
    #subset clicks over threshold 2
    Subset2= Subset1[Subset1$AboveThresh2,]
    while (length(Subset2$UID) > 0) {
      for (i in 1:length(Subset2$UID)) {
        Subset2$BestMatch[i]= which.max(as.numeric(Subset2[i,MatchCol]))
      }
      # find all clicks in Subset2 w/in iMin of first click in Subset2 and over thresholds 
      DateTime= Subset2$UTCdatetime[1]   #time of first high threshold click
      DeltaTime1= abs(difftime(DateTime,Subset1$UTCdatetime,units="min"))
      DeltaTime2= abs(difftime(DateTime,Subset2$UTCdatetime,units="min"))
      EventUIDs= Subset2$UID[DeltaTime2 < iMin]
      Tab= tabulate(Subset2$BestMatch[DeltaTime2 < iMin],nbins=numTemplates)
      BestMatch= which.max(Tab) #find template with highest correlation for the most clicks 
      # find all clicks in subset1 that are w/in iMin and iDeg of a Thresh2 event click
      for (i in 1:length(EventUIDs)) {
        Angle= Subset2$angleDeg[Subset2$UID == EventUIDs[i]]
        UIDs2Add= Subset1$UID[(abs(Subset1$angleDeg-Angle)<iDeg) & (DeltaTime1 < iMin)]
        EventUIDs= c(EventUIDs,UIDs2Add)
      }
      EventUIDs= sort(unique(EventUIDs))
      if (length(EventUIDs) > 2) {
          # create events for the EventUIDs in BinaryFile
          nEvents= nEvents + 1
          cat(TemplNames[BestMatch],nEvents,length(EventUIDs),BestMatch,"   ",as.character(DateTime),"\n")
          results= addPgEvent(db=DataBase,binary=BinaryFile,UIDs=EventUIDs,eventType=as.character(BestMatch),comment=TemplNames[BestMatch])
      }
      Subset1= Subset1[!(Subset1$UID %in% EventUIDs),]  # remove existing event clicks from Subset1
      Subset2= Subset2[!(Subset2$UID %in% EventUIDs),]  # remove existing event clicks from Subset2
      TemplClickDF= TemplClickDF[!(TemplClickDF$UID %in% EventUIDs),] # remove existing event clicks from TemplClickDF
    }
  }


