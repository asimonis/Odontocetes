#Add GPS data to Pamguard database
gps <- 'C:/Users/anne.simonis.NMFS/Documents/code/RoboJay/AllSpotData wUTC.csv'

setwd('H:/NBHF/NBHF_cces/databases_wGPS')
dbFiles<-dir(path='H:/NBHF/NBHF_cces/databases_wGPS',pattern='sqlite3')


db<-dbFiles[14]


gpsDf <- read.csv(gps, stringsAsFactors = FALSE)
gpsDf <- rename(gpsDf, Longitude=long, Latitude=lat)
gpsDf <- filter(gpsDf, Drift == 8)
PAMmisc::addPgGps(db, gpsDf, format='%Y-%m-%d %H:%M:%S')
