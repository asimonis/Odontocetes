
#Investigate co-occurrence of dolphins and beaked whales in Adrift
gps <- readRDS(here('data/AllDeploymentGPS.rds'))
effortBase <- readRDS(here('data/AllDrifts_BaseEffort.rds'))
badPascal <- c('PASCAL_014')
effortBase <- effortBase[!effortBase$DriftName %in% badPascal, ]
effortMin <- effortToBins(effortBase, bin='min')
effortMin_adrift <- filter(effortMin, grepl('ADRIFT', DriftName))


dolData_adrift <- readRDS(here('data/dolphin/ADRIFT_dolphinData.rds')) %>% 
  mutate(call=NA, species='dolphin')
bwData_adrift <- readRDS(here('data/bw/bwData_adrift.rds'))

dolBinAll_adrift <- formatBinnedPresence(dolData_adrift, 
                                         bin='min', 
                                         effort=effortMin_adrift,
                                         gps=gps)
dolBinPres_adrift <- filter(dolBinAll_adrift,!is.na(species))


bwSpecies <- c('ZC', 'BB', 'BW39V', 'MS', 'BW43', 'BW37V', 'MC', 'BW', 'BWC')
bwBinAll_adrift <- formatBinnedPresence(
  filter(bwData_adrift, species %in% bwSpecies) %>% 
    mutate(call=species,
           species='bw'),
  effort=effortMin_adrift,
  bin='min',
  gps=gps)
bwBinPres_adrift<-filter(bwBinAll_adrift,!is.na(species))


#Calculate closest time to a dolphin detection for every
#minute with a beaked whale detection 

##Need to look on the same drift
bwBinPres_adrift$TimeToDolphin<-NA

#1. create dolphin and bw minute dataframes for a single drift
#2. Then calculate time to nearest dolphin detection for each bw detection
#3. Save new dataframe with bw event start time, drift name, time to dolphin presence, Site 
AllDriftBW<-data.frame()
Drifts<-unique(effortMin_adrift$DriftName)
for(d in 1:length(Drifts)){
  DriftBW<-filter(bwBinPres_adrift,DriftName==Drifts[d])
  #if no beaked whales on this drift, go to the next one
  if(nrow(DriftBW)==0){next}
  DriftDol<-filter(dolBinPres_adrift,DriftName==Drifts[d])
  #if no dolphins on this drift, record TimeToDolphin as NA
  if(nrow(DriftDol==0)){DriftBW$TimeToDolphin<-NA}
  if(nrow(DriftDol)>0){
   for(b in 1:nrow(DriftBW)){
      DolphinDelta<-as.numeric(difftime(DriftBW$UTC[b],DriftDol$UTC,units="mins"))
      MinInd<-which.min(abs(DolphinDelta))
      DriftBW$TimeToDolphin[b]<-DolphinDelta[MinInd]
   }
  }
  AllDriftBW<-rbind(AllDriftBW,DriftBW)
}

ggplot(AllDriftBW,aes(TimeToDolphin))+facet_grid(DeploymentSite~.)+
  geom_histogram(binwidth=30)

