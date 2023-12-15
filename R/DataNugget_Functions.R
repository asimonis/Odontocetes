HourlyBin<-function(Species,detection_dir,DetectionTab){
  
  logFiles<-list.files(path=detection_dir,pattern='*.xls',full.names = TRUE)
  
  # detData <- loadDetectionData(logFiles, source='triton',sheet='AdhocDetections')
  # #bin data into hourly presence
  # binned <- formatBinnedPresence(detData, bin='hour', gps=gps)
  
  #Load detections into a single dataframe
  df<-lapply(logFiles,function(i){
    read.xlsx(i,sheetName = DetectionTab)
  })
  
  Adrift.id<-lapply(logFiles,function(i){ 
    str_extract(i,'[ADRIFT_]+_[0-9]{3}')
    })
  
  for(d in 1:length(Adrift.id)){
  df[[d]]$Adrift.id<-as.character(Adrift.id[d])
  }
  df<-bind_rows(df)
  
  #Only keep detections of interest
  SpDf<-df %>% 
    filter(Species.Code %in% Species) %>%
    mutate(Start_time_floor = floor_date(Start.time,unit="hour"),
           End_time_floor = floor_date(End.time,unit="hour")) 
  
  #Create dataframe with all species-positive hours
  SpHoursAll<-seq.POSIXt(SpDf$Start_time_floor[1],SpDf$End_time_floor[1],by="hour")
  IdAll<-rep(SpDf$Adrift.id[1],length(SpHoursAll))
  
  for(p in 2:nrow(SpDf)){
    SpHours<-seq.POSIXt(SpDf$Start_time_floor[p],SpDf$End_time_floor[p],by="hour")
    Id<-rep(SpDf$Adrift.id[p],length(SpHours))
    
    SpHoursAll<-c(SpHoursAll,SpHours)
    IdAll<-c(IdAll,Id)
  }
  
  SpHours<-data.frame(DateTime = SpHoursAll,Adrift.id=IdAll,Sp_pres=1)
  
  return(SpHours)
}