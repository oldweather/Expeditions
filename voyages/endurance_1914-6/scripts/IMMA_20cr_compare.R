# Compare data from Endurance and 20CR

library(IMMA)
library(GSDF.TWCR)
library(parallel)

# Get the observations for this ship
o<-IMMA.read('../../../imma/Endurance_1914-16.imma')
w<-which(!is.na(o$YR) & !is.na(o$MO) & !is.na(o$DY) &
         !is.na(o$HR) & !is.na(o$LAT) & !is.na(o$LON))
o<-o[w,]
version<-'3.5.1'

# Get mean and spread for each ob.
  
get.comparisons<-function(i) {
  
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  t2m<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,
                              version=version)
  tt<-GSDF.interpolate.ll(t2m,o$Latitude[i],o$Longitude[i])  
  t2m<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,
                              type='spread',
                              version=version)
  tt.spread<-GSDF.interpolate.ll(t2m,o$Latitude[i],o$Longitude[i])  
  old<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              version=version)
  mean<-GSDF.interpolate.ll(old,o$Latitude[i],o$Longitude[i])
  old<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                              type='spread',
                              version=version)
  spread<-GSDF.interpolate.ll(old,o$Latitude[i],o$Longitude[i])
  #if(i==10) break
  return(c(i,tt,tt.spread,mean,spread))
}

#lapply(seq_along(o$V1),get.comparisons)
r<-mclapply(seq_along(o$V1),get.comparisons,mc.cores=6)
r<-mclapply(seq(1,10),get.comparisons,mc.cores=6)
r<-unlist(r)
odr<-r[seq(1,length(r),5)]
tt<-r[seq(2,length(r),5)]
tt.spread<-r[seq(3,length(r),5)]
mean<-r[seq(4,length(r),5)]
spread<-r[seq(5,length(r),5)]

# Output the result
fileConn<-file(sprintf("Enduurance.comparisons"))
writeLines(sprintf("%d %d %d %d %f %f %f %f %f %f",
                   o$YR[odr],o$MO[odr],o$DY[odr],as.integer(o$HR[odr]),
                   o$SLP[odr],mean/100,spread/100,
                   o$AT[odr],tt-273.15,tt.spread),
                   fileConn)
close(fileConn)
