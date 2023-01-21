#How to convert cepstral freq to ICI
#Convert Freq to bin # first (Freq * N / SR)
#Then the ICI is Bin # / SR
#For harmonic spacing you just invert the ICI

freq1<-2000
freq2<-100000
Nfft<-2048
Fs<-200000


ICI1<-(freq1*Nfft)/(Fs^2)
HarmonicSpace1<-1/ICI1

ICI2<-(freq2*Nfft)/(Fs^2)
HarmonicSpace2<-1/ICI2

HarmonicSpace2
HarmonicSpace1

paste('Frequency range of',freq1/1000,'-',freq2/1000,'kHz',
      'in the cepstral space corresponds to an ICI between',
      ICI1*1000,'-',ICI2*1000,'ms',
      'or equivalently Harmonics separated by ',
      HarmonicSpace2, '-', HarmonicSpace1,'Hz')
