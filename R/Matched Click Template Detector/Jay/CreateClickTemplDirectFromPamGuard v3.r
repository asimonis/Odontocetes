# Create click waveform templates directly from PAMGuard and recordings.
#  Will select PamGuard Events of type "TC" (template click)
#  Requires that the PamGuard settings be saved as an XML file
#  At the end, the click waveform template csv files must be editted to replace
#     the NAs with nothing (keeping the commas) using text editor like Notepad++
#  Requires version 0.14 or higher of PAMpal

#  Note, waveform data to create templates is actually taken from WAV files (because
#     PAMGuard click binary data may be decimated)
##########################
library(PAMmisc)
library(PAMpal)   #note, this needs v. 0.14 or higher of PAMpal
library(tuneR)
library(signal)

library(devtools)
library(remotes)
devtools::install_github('TaikiSan21/PamBinaries')
remotes::install_github("TaikiSan21/PAMmisc")
devtools::install_github('TaikiSan21/PAMPal')

############################################################################
# Input paths to PAMGuard files, sound files, etc. 
############################################################################

setwd()
# set parameters for clicks 
# set truncation length of actual click (in msec, must be less than TemplDuration
ClickDuration= 0.5
# set template duration (in msec) including zero padding at each end
TemplDuration=1   #(must be longer than ClickDuration or will generate error message)
if (ClickDuration > TemplDuration) stop("ERROR:  click duration is longer than template duration")
lowfilter= 100000     #waveform bandpass filter lower value in Hz
highfilter= 160000   #waveform bandpass filter higher value in Hz


# DB and Binaries for processing
# db <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/Database/Bangarang_20150613_Dalls_Porpoise.sqlite3'
# bin <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/Binaries/Bangarang_20150613_DallsPorpoise/20150613'
db <- 'H:/Odontocetes/NBHF/Databases/CalCURSeas_Dalls - Copy.sqlite3'
# db <- 'D:/NBHF/NBHF_cces/databases/PamGuard64 2_00_16e NBHF CCES-Drift-21_JST_final.sqlite3'
# db <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/Database/Bangarang_20150613_Dalls_Porpoise.sqlite3'

bin <-'H:/Odontocetes/NBHF/Binaries/CalCURSeas_Dalls - Copy'
# bin <- 'D:/NBHF/NBHF_cces/binaries/Drift-21 (completed by JST)'
# bin <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/Binaries/Bangarang_20150613_DallsPorpoise/20150613'

# db <- 'G:/Odontocetes/NBHF/Databases/OPPS_010_NBHF.sqlite3'
# bin <- 'G:/Odontocetes/NBHF/Binaries/OPPS_010'
# 
# Input path where original acoustic files are located 
Acoustic_files_folder <- 'D:/Raw/CalCURSeas/Array/Dalls Porpoise/20140811_155924'
#Acoustic_files_folder <- 'E:/CCES_2018_RECORDINGS/Drift-21/1208791071'
# Acoustic_files_folder <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/Recordings'
# Acoustic_files_folder <-'G:/Odontocetes/NBHF/Classification/OPPS_010_Harbor_Porpoise/Recordings'
# 
# Input path to the XML file exported from PAMGuard 
xmlFile <- 'H:/Odontocetes/NBHF/PG settings/CalCurseas_Dalls_2.xml'
# xmlFile <- 'D:/Click Templates/PAM2.02.02_CCES_021_NBHF.xml'
# xmlFile <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/PG/Bangarang_20150613_Dalls_Porpoise_Settings.xml'
# xmlFile <- 'G:/Odontocetes/NBHF/Classification/OPPS_010_Harbor_Porpoise/OPPS_010_Pp.xml'

# Set path where wav clips will be stored 
WavClipFolder <- 'C:/Users/anne.simonis/Documents/GitHub/Odontocetes/data/Species_template_csvs'
# WavClipFolder <- 'G:/Odontocetes/NBHF/Classification/Keen_Dalls_Porpoise/WavClips'
# WavClipFolder <- 'G:/Odontocetes/NBHF/Classification/OPPS_010_Harbor_Porpoise/WavClips'
############################################################################
# Load PAMGuard data as Acoustic Study Object 
############################################################################

# Run PAMpal (any settings here can be changed to your desired values)
pps <- PAMpalSettings(db=db, binaries=bin, sr_hz='auto', filterfrom_khz=100, filterto_khz=160, winLen_sec=.0025, settings=xmlFile)
# pps <- PAMpalSettings(db=db, binaries=bin, sr_hz='auto', filterfrom_khz=100, filterto_khz=160, winLen_sec=.0025, settings=xmlFile)
# Process PAMGuard data into the Acoustic Study Object 
data <- processPgDetections(pps, mode='db', id="CalCurseas_Dalls")

# Add GPS, Depth, and recording folder info (with original acoustic files)
data <- addRecordings(data,folder = Acoustic_files_folder, log=FALSE)

# Filtering by event type (TC events)
# goodData <- data
goodData<- setSpecies(data, method='pamguard') # uses PAMGuard event type as species
# goodData<- filter(goodData@events,species=='TC')

############################################################################
# Create wav clips - may need to adjust duration (buffer) or channel 
############################################################################

# Folder where wav clips should be stored, if it doesn't exist yet function will create it
clipDir <- WavClipFolder

# create wav clips 
wavs <- writeEventClips(goodData, 
            buffer = c(0.0,0.04), # amount to include before and after event in seconds
            outDir = clipDir, # export directory 
            mode = 'detection', 
            channel = 1,
            verbose = TRUE,
            useSample = TRUE) # whether to use start sample or time for indexing 


############################################################################
# Get wav clip file names and loop through all files
############################################################################
files= list.files(path=clipDir,pattern=glob2rx("Detection*.wav"),recursive=FALSE,full.names=TRUE)
nfiles= length(files)
for (ifile in 1:nfiles) {
  filename= files[ifile]
  cat(filename,"\n")
  # plot original waveform data
  FullClip= readWave(filename)
  FullClip= normalize(FullClip,center=TRUE,rescale=TRUE)
  plot(FullClip)
  Fs= FullClip@samp.rate
  SampleDuration= length(FullClip)/Fs
  if (SampleDuration < (ClickDuration/1000)) stop("ERROR:  sample signal duration is too long")
  # snip ClickDuration around peak in waveform data
  peak= which.max(abs(FullClip@left))
  ClickSamples= Fs*ClickDuration/1000
  SnipClip= extractWave(FullClip,from=(peak-ClickSamples/2),to=(peak+ClickSamples/2),xunit="samples")
  # plot snip around maximum value 
  plot(SnipClip)
  # apply 4-pole butterworth band-pass filter 
  nyq= Fs/2
  low= lowfilter/nyq; high= highfilter/nyq
  bf <- butter(4, W=c(low,high),type="pass")
  val= filter(bf,SnipClip@left)
  # reduce amplitude to 25% of max (not sure why this was necessary)
  val= 0.25 * val/(max(abs(val)))
  # add zero padding to both ends of sample for a sample of length Fs*TemplDuration/1000
  n= length(val)
  add= ((Fs*TemplDuration/1000) - n)/2
  # create first row of output csv from zero-padded data
  row1= c(rep(0,add),val,rep(0,add))
  if (length(row1) != (Fs*TemplDuration/1000)) row1= c(row1,0)   #add another zero if zero-padding should have been an odd number
  plot(row1,type="l")
  # second row of output csv includes only sample rate and duration
  row2= array(NA,(Fs*TemplDuration/1000))
  row2[1]= Fs
  # merge two rows and export as csv
  output= rbind(row1,row2)
  write.table(output,file=paste(filename,'.csv',sep=''),col.names=F,row.names=F,sep=',')
  # note, for PamGuard template classifier, the NAs need to be replace with nothing using a text editor 
  
}
