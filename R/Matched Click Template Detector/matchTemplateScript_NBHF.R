library(here)
library(PAMpal)

source(here('R','Matched Click Template Detector','matchTemplateFunctions.R'))


###USER-DEFINED FIELDS####
DriftName<-'PG2_02_09_CCES_022_Ksp'
binFolder <- 'H:/Odontocetes/NBHF/TrainingData/PG2_02_09_CCES_022_Ksp'
# this database should be a COPY of the original because we will add events to it later
db <- 'H:/Odontocetes/NBHF/TrainingData/PG2_02_09_CCES_022_Ksp - Copy.sqlite3'
###########################


# change if the set of templates changes
templateNames <- c("Pd_1","Pd_2",'Pp','Ksp')
# keeping the match/reject values just in case they are useful, but
# can remove these in future if they aren't necessary
extraCols <- c(paste0(templateNames, '_match'))

baseDir <- 'H:/Odontocetes/NBHF/TrainingData'

# the binary processing takes a really long time, this automatically saves to an RDS file
# so that you don't have to reprocess in future
saveFile <- file.path(baseDir, paste0(DriftName,'_Template.rds'))

allData <- loadTemplateFolder(binFolder, names=templateNames, extraCols=extraCols, file=saveFile)
# these are in order of "templateNames" above. Can look at data and see if any of these need to
# be raised/lowered
threshVals <- c(0.45,0.45,0.6,0.45)
allData <- addTemplateLabels(allData, db, templateNames, threshVals)
# nDets is minimum detections to count as an event, nSeconds is max time between detections
# before an event is ended
allData <- markGoodEvents(allData, nDets=3, nSeconds=120)

# # summary of how many of the detections in manually annotated events were tagged by template
# manualSummary <- summariseManualEvents(allData)
# # summary of how many detections tagged by template were present in manually annotated events
# templateSummary <- summariseTemplateEvents(allData)

# adds events meeting nDets/nSeconds criteria to the database
# make sure db is a COPY of the original for safety
addTemplateEvents(db, binFolder, allData)

### OPTIONAL process again with PAMpal to do stuff ###
library(PAMpal)
pps <- PAMpalSettings(db, binFolder, sr_hz='auto', filterfrom_khz=100, filterto_khz=160, winLen_sec=.0025)
data <- processPgDetections(pps, mode='db', id=paste0('MatchTemp_',DriftName))
data <- setSpecies(data, method = 'pamguard')
# new "FP" and "TP" events in addition to originals
table(species(data))
saveRDS(data, paste0(baseDir,'matchTemplateStudy_',DriftName,'.rds'))
