# Look at ice coverage effects on ship speed

library(IMMA)
library(GSDF.TWCR)
library(parallel)

# Get the observations for this ship
o<-IMMA::ReadObs('../../../imma/Endurance_1914-16.imma')
o$chron<-chron(dates=sprintf("%04d/%02d/%02d",o$YR,o$MO,o$DY),
             times=sprintf("%02d:00:00",as.integer(o$HR)),
             format=c(dates = "y/m/d", times = "h:m:s"))
load('Endurance.comparisons.icec.modern.Rdata')

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

# Calculates the geodesic distance between two lat,lon points 
#   using the Haversine formula
distance <- function(long1, lat1, long2, lat2) {
  long1<-long1*pi/180
  lat1<-lat1*pi/180
  long2<-long2*pi/180
  lat2<-lat2*pi/180
  R <- 6371 # Earth mean radius [km]
  delta.long <- (long2 - long1)
  delta.lat <- (lat2 - lat1)
  a <- sin(delta.lat/2)^2 + cos(lat1) * cos(lat2) * sin(delta.long/2)^2
  c <- 2 * asin(pmin(1,sqrt(a),na.rm=TRUE))
  d = R * c
  return(d) # Distance in km
}

# Estimate the speed of the ship at each point
speed<-distance(c(o$LON,NA),c(o$LAT,NA),c(NA,o$LON),c(NA,o$LAT))/c(NA,diff(o$chron),NA)
w<-which(speed>1000)
is.na(speed[w])<-TRUE

# Get the ice cover from the reanalyses
Twcr<-read.table('Endurance.comparisons',header=FALSE)
Era<-read.table('Endurance.comparisons.ERA20C',header=FALSE)

# Plot the speed and coverage when entering and leaving the ice
pdf(file="Endurance_speed_v_ice.pdf",
    width=10*sqrt(2),height=10,family='Helvetica',
    paper='special',pointsize=18,bg='white')

# Enter the ice
id<-chron(dates=c("1914/10/27","1915/02/08"),
          times=c("00:00:00","23:59:59"),
          format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(id)
ticl=attr(tics,'labels')
pushViewport(viewport(width=1.0,height=0.5,x=0.0,y=0.5,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,6)))
      pushViewport(dataViewport(id,c(0,500)))
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Ship speed (km/day)',x=unit(-4,'lines'),rot=90)

         w<-which(o$chron>id[1] & o$chron<id[2])
         w2<-which(diff(as.integer(days(o$chron[w])))!=0)
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(o$chron[w][w2],'native'),
                     y=unit(speed[w+1][w2],'native'),
                     size=unit(0.02,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
      pushViewport(dataViewport(id,c(0,1)))
         grid.yaxis(main=F)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
         grid.text('Ice (Fraction)',x=unit(1.10,'npc'),rot=90,gp=gp)
         gp=gpar(col=rgb(0.75,0.75,1,1),fill=rgb(0.75,0.75,1,1),lty=1,lwd=0.5)
         for(i in seq(1,30)) {
	     grid.lines(x=unit(o$chron[w],'native'),
			y=unit(endurance.icec.modern[i,w+1],'native'),
			 gp=gp)
         }
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=1,lwd=2)
         grid.lines(x=unit(o$chron[w],'native'),
                    y=unit(Twcr$V14[w+1],'native'),
                     gp=gp)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=2,lwd=2)
         grid.lines(x=unit(o$chron[w],'native'),
                    y=unit(Era$V14[w+1],'native'),
                     gp=gp)
      popViewport()
   popViewport()
popViewport()

# leave the ice
id<-chron(dates=c("1916/02/15","1916/04/12"),
          times=c("00:00:00","23:59:59"),
          format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(id)
ticl=attr(tics,'labels')
pushViewport(viewport(width=1.0,height=0.5,x=0.0,y=0.0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,6)))
      pushViewport(dataViewport(id,c(0,500)))
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Ship speed (km/day)',x=unit(-4,'lines'),rot=90)

         w<-which(o$chron>id[1] & o$chron<id[2])
         w2<-which(diff(as.integer(days(o$chron[w])))!=0)
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(o$chron[w][w2],'native'),
                     y=unit(speed[w+1][w2],'native'),
                     size=unit(0.02,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
      pushViewport(dataViewport(id,c(0,1)))
         grid.yaxis(main=F)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
         grid.text('Ice (Fraction)',x=unit(1.10,'npc'),rot=90,gp=gp)
         gp=gpar(col=rgb(0.75,0.75,1,1),fill=rgb(0.75,0.75,1,1),lty=1,lwd=0.5)
         for(i in seq(1,30)) {
	     grid.lines(x=unit(o$chron[w],'native'),
			y=unit(endurance.icec.modern[i,w+1],'native'),
			 gp=gp)
         }
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=1,lwd=2)
         grid.lines(x=unit(o$chron[w],'native'),
                    y=unit(Twcr$V14[w+1],'native'),
                     gp=gp)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=2,lwd=2)
         grid.lines(x=unit(o$chron[w],'native'),
                    y=unit(Era$V14[w+1],'native'),
                     gp=gp)
      popViewport()
   popViewport()
popViewport()
dev.off()
