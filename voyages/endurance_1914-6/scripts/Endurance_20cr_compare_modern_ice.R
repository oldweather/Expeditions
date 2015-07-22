# Compare ice data from Endurance and 20CR

library(IMMA)
library(GSDF.TWCR)
library(parallel)

# Get the observations for this ship
o<-IMMA::ReadObs('../../../imma/Endurance_1914-16.imma')
o$chron<-chron(dates=sprintf("%04d/%02d/%02d",o$YR,o$MO,o$DY),
             times=sprintf("%02d:00:00",as.integer(o$HR)),
             format=c(dates = "y/m/d", times = "h:m:s"))

# Fill in gaps in the obs series - just to make the reanalysis series continuous
o.add<-o[1,]
for(i in seq(1,length(o.add))) is.na(o.add[[i]])<-T
c.date<-o[2,]$chron+1
while(c.date<o[length(o$YR)-1,]$chron-1) {
   year<-as.integer(as.character(years(c.date)))
   month<-as.integer(months(c.date))
   day<-as.integer(days(c.date))
   for(hour in c(0,6,12,18)) {
      w<-which(o$YR==year & o$MO==month & o$DY==day & abs(o$HR-hour)<3)
      if(length(w)>0) next
      insert<-o.add
      insert$YR<-year
      insert$MO<-month
      insert$DY<-day
      insert$HR<-hour
      insert$chron<-chron(dates=sprintf("%04d/%02d/%02d",year,month,day),
                          times=sprintf("%02d:00:00",hour),
                          format=c(dates = "y/m/d", times = "h:m:s"))
      before<-max(which(o$chron<insert$chron))
      after<-min(which(o$chron>insert$chron))
      weight<-(as.numeric(insert$chron)-as.numeric(o[before,]$chron))/
              (as.numeric(o[after,]$chron)-as.numeric(o[before,]$chron))
      insert$LAT<-o[after,]$LAT*weight+o[before,]$LAT*(1-weight)
      insert$LON<-o[after,]$LON*weight+o[before,]$LON*(1-weight)
      w<-which(o$chron<insert$chron)
      o<-rbind(o[w,],insert,o[-w,])
   }
   c.date<-c.date+1
}


version<-'3.4.1'

# Will probably run this more than once, cache the field accesses.
GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))

# Get means and spreads for each ob.
  
get.comparisons<-function(i) {
  
  if(any(is.na(o$YR[i]),is.na(o$MO[i]),is.na(o$DY[i]),
         is.na(o$HR[i]),is.na(o$LAT[i]),is.na(o$LON[i]))) {
    return(rep(NA,30))
  }
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  r<-rep(NA,30)
  for(year in seq(1981,2010)) {
     if(month==2 && day==29) day=28
     if(month==1 && day==1 && hour <6) hour=6
     if(month==12 && day==31 && hour>18) hour=18
     print(sprintf("%04d %04d-%02d-%02d:%02d",i,year,month,day,hour))
     icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                                 version=version)
     r[year-1980]<-GSDF.interpolate.ll(icec,o$LAT[i],o$LON[i],greedy=TRUE)

  }
  return(r)
}

#r<-lapply(seq(1,10),get.comparisons)
r<-lapply(seq_along(o$YR),get.comparisons)
#r<-mclapply(seq_along(o$YR),get.comparisons,mc.cores=1)
r<-unlist(r)
endurance.icec.modern<-array(data=r,dim=c(30,length(r)/30))
# Output the result
save(endurance.icec.modern,
     file=sprintf("Endurance.comparisons.icec.modern.Rdata"))
