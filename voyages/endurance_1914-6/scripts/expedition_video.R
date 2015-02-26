# Show the Route of the ships along with a Reanalysis comparison

library(GSDF.WeatherMap)
library(chron)
library(GSDF)
library(GSDF.TWCR)
library(parallel)
library(IMMA)

Endurance<-read.table('Endurance.comparisons')
Endurance.imma<-IMMA.read('../../../imma/Endurance_1914-16.imma')
Endurance$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Endurance$V1,
                          Endurance$V2,Endurance$V3),
                    times=sprintf("%02d:00:00",Endurance$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

Aurora<-read.table('Aurora.comparisons')
Aurora.imma<-IMMA.read('../../../imma/Aurora_1914-16.imma')
Aurora$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Aurora$V1,
                          Aurora$V2,Aurora$V3),
                    times=sprintf("%02d:00:00",Aurora$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

lDates<-c(Endurance$Dates,Aurora$Dates)
tics=pretty(lDates)
ticl=attr(tics,'labels')

GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))
if(!file.exists(GSDF.cache.dir)) dir.create(GSDF.cache.dir,recursive=TRUE)
Imagedir<-sprintf("%s/images/ITAE/",Sys.getenv('GSCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'show.mslp',F)
Options<-WeatherMap.set.option(Options,'show.ice',T)
Options<-WeatherMap.set.option(Options,'show.obs',T)
Options<-WeatherMap.set.option(Options,'show.fog',F)
Options<-WeatherMap.set.option(Options,'show.wind',F)
Options<-WeatherMap.set.option(Options,'show.temperature',F)
Options<-WeatherMap.set.option(Options,'show.precipitation',F)
Options<-WeatherMap.set.option(Options,'temperature.range',12)
Options<-WeatherMap.set.option(Options,'obs.size',1.5)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'lat.min',-55)
Options<-WeatherMap.set.option(Options,'lat.max',55)
Options<-WeatherMap.set.option(Options,'lon.min',-50)
Options<-WeatherMap.set.option(Options,'lon.max',150)
Options<-WeatherMap.set.option(Options,'pole.lon',180)
Options<-WeatherMap.set.option(Options,'pole.lat',50)
Options<-WeatherMap.set.option(Options,'label.xp',0.49)
Options<-WeatherMap.set.option(Options,'background.resolution','high')
Options$ice.points<-50000

set.pole<-function(Date,Options) {
  start.date<-chron(dates='1914/08/08',
                    times="01:00:00",
                    format=c(dates='y/m/d',times='h:m:s'))
  fix.date<-chron(dates='1915/01/01',
                    times="01:00:00",
                    format=c(dates='y/m/d',times='h:m:s'))
  if(Date<=start.date) {
    Options<-WeatherMap.set.option(Options,'pole.lon',180)
    Options<-WeatherMap.set.option(Options,'pole.lat',50)
  }
  if(Date>=fix.date) {
    Options<-WeatherMap.set.option(Options,'pole.lon',110)
    Options<-WeatherMap.set.option(Options,'pole.lat',179)
  }
  if(Date>start.date & Date<fix.date) {
    Options<-WeatherMap.set.option(Options,'pole.lon',
                      180-70*(Date-start.date)/(fix.date-start.date))
    Options<-WeatherMap.set.option(Options,'pole.lat',
                      50+129*(Date-start.date)/(fix.date-start.date))    
  }
  return(Options)
}
  
# Make the selected plot

plot.time<-function(c.date) {

   year=as.numeric(as.character(years(c.date)))
   month=months(c.date)
   day=days(c.date)
   hour=hours(c.date)
   
    image.name<-sprintf("%04d-%02d-%02d:%02d.png",year,month,day,hour)
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    if(file.exists(ifile.name) && file.info(ifile.name)$size>1000) return()
    print(sprintf("%04d-%02d-%02d:%02d",year,month,day,hour))

    Options.local<-set.pole(c.date,Options)
    icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                                 version='3.5.1')
    
    png(ifile.name,
                 width=1080*WeatherMap.aspect(Options.local),
                 height=1080,
                 bg=Options.local$sea.colour,
                 pointsize=24,
                 type='cairo')
      Options.local$label<-sprintf("%04d-%02d-%02d",year,month,day)

      base.gp<-gpar(family='Helvetica',font=1,col='black')
      pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
                                c(Options$lat.min,Options$lat.max),
                                extension=0,gp=base.gp))

      ip<-WeatherMap.rectpoints(Options.local$ice.points,Options.local)
      WeatherMap.draw.ice(ip$lat,ip$lon,icec,Options.local)
      WeatherMap.draw.land(NULL,Options.local)

      w<-which(Endurance$Dates<c.date)  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,55,maxColorValue=255))
          ot<-list(Longitude=Endurance.imma$LON[w],
                   Latitude=Endurance.imma$LAT[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(Endurance$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,0,0,255,maxColorValue=255))
          ot<-list(Longitude=Endurance.imma$LON[w],
                   Latitude=Endurance.imma$LAT[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(Aurora$Dates<c.date)  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,55,maxColorValue=255))
          ot<-list(Longitude=Aurora.imma$LON[w],
                   Latitude=Aurora.imma$LAT[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(Aurora$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(0,0,255,255,maxColorValue=255))
          ot<-list(Longitude=Aurora.imma$LON[w],
                   Latitude=Aurora.imma$LAT[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      if(Options$label != '') {
            WeatherMap.draw.label(Options.local)
      }

   # Add the data plots
    pushViewport(viewport(width=0.5,height=1.0,x=0.5,y=0.0,
                          just=c("left","bottom"),name="Page",clip='off'))

    # Plain background
    grid.polygon(x=unit(c(0,1,1,0),'npc'),y=unit(c(0,0,1,1),'npc'),
                 gp=gpar(col='white',fill='white'))

    w<-which(Endurance$Dates<=c.date)  
   # Endurance pressure
    pushViewport(viewport(width=1.0,height=0.34,x=0.0,y=0.0,
                          just=c("left","bottom"),name="Page",clip='off'))
       pushViewport(plotViewport(margins=c(4,6,0,0)))
          pushViewport(dataViewport(lDates,c(970,1040)))
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Pressure (hPa)',x=unit(-4,'lines'),rot=90)
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w)>0) {
	     for(i in seq_along(Endurance$V1[w])) {
		x<-c(Endurance$Dates[i]-0.125,Endurance$Dates[i]+0.125,
		     Endurance$Dates[i]+0.125,Endurance$Dates[i]-0.125)
		y<-c(Endurance$V6[i]-(Endurance$V7[i])*2,
		     Endurance$V6[i]-(Endurance$V7[i])*2,
		     Endurance$V6[i]+(Endurance$V7[i])*2,
		     Endurance$V6[i]+(Endurance$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V5[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
          popViewport()
       popViewport()
    popViewport()
   # Endurance air temperature
    pushViewport(viewport(width=1.0,height=0.22,x=0.0,y=0.34,
                          just=c("left","bottom"),name="Page",clip='off'))
       pushViewport(plotViewport(margins=c(1,6,1,0)))
          pushViewport(dataViewport(lDates,c(-20,30)))
         grid.yaxis(main=T)
         grid.text('Air temperature (C)',x=unit(-4,'lines'),rot=90)
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w)>0) {
	     for(i in seq_along(Endurance$V1[w])) {
		x<-c(Endurance$Dates[i]-0.125,Endurance$Dates[i]+0.125,
		     Endurance$Dates[i]+0.125,Endurance$Dates[i]-0.125)
		y<-c(Endurance$V9[i]-(Endurance$V10[i])*2,
		     Endurance$V9[i]-(Endurance$V10[i])*2,
		     Endurance$V9[i]+(Endurance$V10[i])*2,
		     Endurance$V9[i]+(Endurance$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V8[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
          popViewport()
       popViewport()
    popViewport()
    w<-which(Aurora$Dates<=c.date)  
   # Aurora pressure
    pushViewport(viewport(width=1.0,height=0.22,x=0,y=0.34+0.22,
                          just=c("left","bottom"),name="Page",clip='off'))
       pushViewport(plotViewport(margins=c(1,6,1,0)))
          pushViewport(dataViewport(lDates,c(960,1030)))
         grid.yaxis(main=T)
         grid.text('Pressure (hPa)',x=unit(-4,'lines'),rot=90)
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w)>0) {
	     for(i in seq_along(Aurora$V1[w])) {
		x<-c(Aurora$Dates[i]-0.125,Aurora$Dates[i]+0.125,
		     Aurora$Dates[i]+0.125,Aurora$Dates[i]-0.125)
		y<-c(Aurora$V6[i]-(Aurora$V7[i])*2,
		     Aurora$V6[i]-(Aurora$V7[i])*2,
		     Aurora$V6[i]+(Aurora$V7[i])*2,
		     Aurora$V6[i]+(Aurora$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
	     grid.points(x=unit(Aurora$Dates[w],'native'),
			 y=unit(Aurora$V5[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
          }
          popViewport()
       popViewport()
    popViewport()
   # Aurora air temperature
    pushViewport(viewport(width=1.0,height=0.22,x=0,y=0.34+0.22+0.22,
                          just=c("left","bottom"),name="Page",clip='off'))
       pushViewport(plotViewport(margins=c(1,6,1,0)))
          pushViewport(dataViewport(lDates,c(-20,30)))
         grid.yaxis(main=T)
         grid.text('Air temperature (C)',x=unit(-4,'lines'),rot=90)
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w)>0) {
	     for(i in seq_along(Aurora$V1[w])) {
		x<-c(Aurora$Dates[i]-0.125,Aurora$Dates[i]+0.125,
		     Aurora$Dates[i]+0.125,Aurora$Dates[i]-0.125)
		y<-c(Aurora$V9[i]-(Aurora$V10[i])*2,
		     Aurora$V9[i]-(Aurora$V10[i])*2,
		     Aurora$V9[i]+(Aurora$V10[i])*2,
		     Aurora$V9[i]+(Aurora$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
	     grid.points(x=unit(Aurora$Dates[w],'native'),
			 y=unit(Aurora$V8[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
          }
          popViewport()
       popViewport()
    popViewport()

popViewport()
    
    dev.off()
    #gc(verbose=F)
}

Dates = list()
count=1
c.date<-chron(dates="1914/08/08",times="00:00:00",
          format=c(dates='y/m/d',times='h:m:s'))
e.date<-chron(dates="1916/03/31",times="23:59:59",
          format=c(dates='y/m/d',times='h:m:s'))

Dates = list()
count=1
while(c.date<e.date) {
  for(hour in seq(0,23)) {
     Dates[[count]]<-c.date+hour/24
     count<-count+1
   }
  c.date<-c.date+1
}

#plot.time(Dates[[10000]])

mclapply(Dates,plot.time,mc.cores=8,mc.preschedule=FALSE)
