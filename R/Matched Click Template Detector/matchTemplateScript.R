
library(here)
library(beepr)

source(here('R','Matched Click Template Detector','matchTemplateFunctions.R'))
# change if the set of templates changes
templateNames <- c("ZC","BW43","BW39V","MS","BB","BW70")
# keeping the match/reject values just in case they are useful, but
# can remove these in future if they aren't necessary
extraCols <- c(paste0(templateNames, '_match'))

baseDir <- 'H:/Odontocetes/Beaked whales/MTC/'
binFolder <-'H:/Odontocetes/Beaked whales/MTC/PG_2_00_16_ADRIFT_019'
# this database should be a COPY of the original because we will add events to it later
db <- file.path(baseDir, 'PG_2_00_16_ADRIFT_019_Template_ShortEvents.sqlite3')
# the binary processing takes a really long time, this automatically saves to an RDS file
# so that you don't have to reprocess in future
saveFile <- file.path(baseDir, 'PG_2_00_16_ADRIFT_019_Template.rds')

allData<-readRDS(saveFile)
allData<-filter(allData,type !=6) #ignore click type 6

# allData <- loadTemplateFolder(binFolder, names=templateNames, extraCols=extraCols, file=saveFile)
beep()
# these are in order of "templateNames" above. Can look at data and see if any of these need to
# be raised/lowered
# threshVals <- c(.06, .15, .15, .15, .15, .15)
threshVals <- c(.3, .3, .3, .3, .3, .3)
allData <- addTemplateLabels(allData, db, templateNames, threshVals)
# nDets is minimum detections to count as an event, nSeconds is max time between detections
# before an event is ended
allData <- markGoodEvents(allData, nDets=3, nSeconds=120)

# summary of how many of the detections in manually annotated events were tagged by template
manualSummary <- summariseManualEvents(allData)
# summary of how many detections tagged by template were present in manually annotated events
templateSummary <- summariseTemplateEvents(allData)

# adds events meeting nDets/nSeconds criteria to the database
# make sure db is a COPY of the original for safety
addTemplateEvents(db, binFolder, allData)

### OPTIONAL process again with PAMpal to do stuff ###
library(PAMpal)
pps <- PAMpalSettings(db, binFolder, sr_hz=288e3, filterfrom_khz=10, filterto_khz=NULL, winLen_sec=.0025)
data <- processPgDetections(pps, mode='db', id='MatchTemp_ADRIFT_019')
data <- setSpecies(data, method = 'pamguard')
# new "FP" and "TP" events in addition to originals
table(species(data))
saveRDS(data, paste0(baseDir,'matchTemplateStudy.rds'))
