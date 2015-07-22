# Ice conditions around Elephant Island

library(IMMA)
library(GSDF.TWCR)
library(GSDF.ERA20C)
library(parallel)

# Start and end dates
o<-as.data.frame(list(YR=c(1916,1916),MO=c(4,10),DY=c(1,30),HR=c(0,23),
        LAT=c(-61.1,-61.1),LON=c(-55.5,-55.5)))
o$chron<-chron(dates=sprintf("%04d/%02d/%02d",o$YR,o$MO,o$DY),
             times=sprintf("%02d:00:00",as.integer(o$HR)),
             format=c(dates = "y/m/d", times = "h:m:s"))

# Generate continuous set of dates
o.add<-o[1,]
for(i in seq(1,length(o.add))) is.na(o.add[[i]])<-T
c.date<-o[1,]$chron+1
while(c.date<o[length(o$YR),]$chron-1) {
   year<-as.integer(as.character(years(c.date)))
   month<-as.integer(months(c.date))
   day<-as.integer(days(c.date))
   for(hour in c(0,6,12,18)) {
      insert<-o.add
      insert$YR<-year
      insert$MO<-month
      insert$DY<-day
      insert$HR<-hour
      insert$chron<-chron(dates=sprintf("%04d/%02d/%02d",year,month,day),
                          times=sprintf("%02d:00:00",hour),
                          format=c(dates = "y/m/d", times = "h:m:s"))
      insert$LAT<-o[1,]$LAT
      insert$LON<-o[1,]$LON
      w<-which(o$chron<insert$chron)
      o<-rbind(o[w,],insert,o[-w,])
   }
   c.date<-c.date+1
}

version<-'3.5.1'

# Will probably run this more than once, cache the field accesses.
GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))

# Get modern data.
  
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
     #print(sprintf("%04d %04d-%02d-%02d:%02d",i,year,month,day,hour))
     icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                                 version=version)
     r[year-1980]<-GSDF.interpolate.ll(icec,o$LAT[i],o$LON[i],greedy=TRUE)

  }
  return(r)
}

r<-lapply(seq_along(o$YR),get.comparisons)
r<-unlist(r)
elephant.icec.modern<-array(data=r,dim=c(30,length(r)/30))

# Get TWCR data
get.comparisons.twcr<-function(i) {
  
  if(any(is.na(o$YR[i]),is.na(o$MO[i]),is.na(o$DY[i]),
         is.na(o$HR[i]),is.na(o$LAT[i]),is.na(o$LON[i]))) {
    return(rep(NA,30))
  }
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  r<-NA
  icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
		  	       version=version)
  r<-GSDF.interpolate.ll(icec,o$LAT[i],o$LON[i],greedy=TRUE)

  return(r)
}

r<-lapply(seq_along(o$YR),get.comparisons.twcr)
elephant.icec.twcr<-unlist(r)

# Get ERA data
get.comparisons.era<-function(i) {
  
  if(any(is.na(o$YR[i]),is.na(o$MO[i]),is.na(o$DY[i]),
         is.na(o$HR[i]),is.na(o$LAT[i]),is.na(o$LON[i]))) {
    return(rep(NA,30))
  }
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  r<-NA
  icec<-ERA20C.get.slice.at.hour('icec',year,month,day,hour)
  r<-GSDF.interpolate.ll(icec,o$LAT[i],o$LON[i],greedy=TRUE)

  return(r)
}

r<-lapply(seq_along(o$YR),get.comparisons.era)
elephant.icec.era<-unlist(r)

# Output the result
save(o,elephant.icec.modern,elephant.icec.twcr,elephant.icec.era,
     file=sprintf("Elephant.comparisons.icec.Rdata"))
