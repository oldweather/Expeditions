# Compare data from James Caird and modern data from MERRA

library(IMMA)
library(GSDF.MERRA)
library(parallel)

# Get the observations for this ship
o<-IMMA::ReadObs('../../../imma/James_Caird_1916.imma')
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


# Will probably run this more than once, cache the field accesses.
GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))

# Get recent wind speeds for each ob.
  
get.comparisons<-function(i) {
  
  if(any(is.na(o$YR[i]),is.na(o$MO[i]),is.na(o$DY[i]),
         is.na(o$HR[i]),is.na(o$LAT[i]),is.na(o$LON[i]))) {
    return(rep(NA,4))
  }
  year<-o$YR[i]
  month<-o$MO[i]
  day<-o$DY[i]
  hour<-as.integer(o$HR[i])
  r<-rep(NA,30)
  for(year in seq(1981,2010)) {
     u10m<-MERRA.get.slice.at.hour('U10M',year,month,day,hour)
     u10m.mean<-GSDF.interpolate.ll(u10m,o$LAT[i],o$LON[i])
     v10m<-MERRA.get.slice.at.hour('V10M',year,month,day,hour)
     v10m.mean<-GSDF.interpolate.ll(u10m,o$LAT[i],o$LON[i])
     r[year-1980]<-sqrt(u10m.mean**2+v10m.mean**2)
  }
  return(r)
}

r<-lapply(seq_along(o$YR),get.comparisons)
r<-unlist(r)
JC.wind.modern<-array(data=r,dim=c(30,length(r)/30))

# Output the result
save(o,JC.wind.modern,
     file=sprintf("JC.wind.modern.Rdata"))
