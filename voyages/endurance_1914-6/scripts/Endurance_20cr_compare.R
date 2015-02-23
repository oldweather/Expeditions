# Compare data from Endurance and 20CR

library(IMMA)
library(GSDF.TWCR)
library(parallel)

# Get the observations for this ship
o<-IMMA.read('../../../imma/Endurance_1914-16.imma')
version<-'3.5.1'

# Will probably run this more than once, cache the field accesses.
GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))

# Get means and spreads for each ob.
  
get.comparisons<-function(i) {
  
  if(any(is.na(o$YR[i]),is.na(o$MO[i]),is.na(o$DY[i]),
         is.na(o$HR[i]),is.na(o$LAT[i]),is.na(o$LON[i]))) {
    return(rep(NA,7))
  }
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  t2m<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,
                              version=version)
  t2m.mean<-GSDF.interpolate.ll(t2m,o$LAT[i],o$LON[i])  
  t2m<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,
                              type='spread',
                              version=version)
  t2m.spread<-GSDF.interpolate.ll(t2m,o$LAT[i],o$LON[i])  
  prmsl<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              version=version)
  prmsl.mean<-GSDF.interpolate.ll(prmsl,o$LAT[i],o$LON[i])
  prmsl<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              type='spread',
                              version=version)
  prmsl.spread<-GSDF.interpolate.ll(prmsl,o$LAT[i],o$LON[i])
  sst<-TWCR.get.slice.at.hour('sst',year,month,day,hour,
                              version=version)
  sst.mean<-GSDF.interpolate.ll(sst,o$LAT[i],o$LON[i],greedy=FALSE)  
  sst<-TWCR.get.slice.at.hour('sst',year,month,day,hour,
                              type='spread',
                              version=version)
  sst.spread<-GSDF.interpolate.ll(sst,o$LAT[i],o$LON[i])  
  icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                              version=version)
  icec.mean<-GSDF.interpolate.ll(icec,o$LAT[i],o$LON[i],greedy=FALSE)  
  return(c(t2m.mean,t2m.spread,prmsl.mean,prmsl.spread,sst.mean,sst.spread,icec.mean))
}

#r<-lapply(seq(1,10),get.comparisons)
r<-lapply(seq_along(o$YR),get.comparisons)
#r<-mclapply(seq_along(o$YR),get.comparisons,mc.cores=1)
r<-unlist(r)
t2m.mean<-r[seq(1,length(r),7)]
t2m.spread<-r[seq(2,length(r),7)]
prmsl.mean<-r[seq(3,length(r),7)]
prmsl.spread<-r[seq(4,length(r),7)]
sst.mean<-r[seq(5,length(r),7)]
sst.spread<-r[seq(6,length(r),7)]
icec.mean<-r[seq(7,length(r),7)]

# Output the result
fileConn<-file(sprintf("Endurance.comparisons"))
writeLines(sprintf("%d %d %d %d %f %f %f %f %f %f %f %f %f %f",
                   o$YR,o$MO,o$DY,as.integer(o$HR),
                   o$SLP,prmsl.mean/100,prmsl.spread/100,
                   o$AT,t2m.mean-273.15,t2m.spread,
                   o$SST,sst.mean-273.15,sst.spread,
                   icec.mean),
                   fileConn)
close(fileConn)
