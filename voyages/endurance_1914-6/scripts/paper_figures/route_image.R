# Show the Route of the ships

library(GSDF.WeatherMap)
library(chron)
library(GSDF)
library(GSDF.TWCR)
library(parallel)
library(IMMA)

Endurance<-read.table('../Endurance.comparisons')
Endurance.4<-read.table('../Endurance.comparisons.354')
Endurance$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Endurance$V1,
                          Endurance$V2,Endurance$V3),
                    times=sprintf("%02d:00:00",Endurance$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

Aurora<-read.table('../Aurora.comparisons')
Aurora.4<-read.table('../Aurora.comparisons.354')
Aurora$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Aurora$V1,
                          Aurora$V2,Aurora$V3),
                    times=sprintf("%02d:00:00",Aurora$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

James_Caird<-read.table('../James_Caird.comparisons')
James_Caird.4<-read.table('../James_Caird.comparisons.354')
James_Caird$Dates<-chron(dates=sprintf("%04d/%02d/%02d",James_Caird$V1,
                          James_Caird$V2,James_Caird$V3),
                    times=sprintf("%02d:00:00",James_Caird$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

EmmaYelcho<-read.table('../Emma+Yelcho.comparisons')
EmmaYelcho.4<-read.table('../Emma+Yelcho.comparisons.354')
EmmaYelcho$Dates<-chron(dates=sprintf("%04d/%02d/%02d",EmmaYelcho$V1,
                          EmmaYelcho$V2,EmmaYelcho$V3),
                    times=sprintf("%02d:00:00",EmmaYelcho$V4),
                       format=c(dates='y/m/d',times='h:m:s'))
lDates<-c(Endurance$Dates,Aurora$Dates,James_Caird$Dates,EmmaYelcho$Dates)
tics=pretty(lDates)
ticl=attr(tics,'labels')

GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('SCRATCH'))
if(!file.exists(GSDF.cache.dir)) dir.create(GSDF.cache.dir,recursive=TRUE)

version='3.5.4'
Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'show.mslp',F)
Options<-WeatherMap.set.option(Options,'show.ice',T)
Options<-WeatherMap.set.option(Options,'show.obs',T)
Options<-WeatherMap.set.option(Options,'show.fog',F)
Options<-WeatherMap.set.option(Options,'show.wind',F)
Options<-WeatherMap.set.option(Options,'show.temperature',F)
Options<-WeatherMap.set.option(Options,'show.precipitation',F)
Options<-WeatherMap.set.option(Options,'temperature.range',12)
Options<-WeatherMap.set.option(Options,'obs.size',0.5)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'lat.min',-55)
Options<-WeatherMap.set.option(Options,'lat.max',55)
Options<-WeatherMap.set.option(Options,'lon.min',-55)
Options<-WeatherMap.set.option(Options,'lon.max',55)
Options<-WeatherMap.set.option(Options,'pole.lon',180)
Options<-WeatherMap.set.option(Options,'pole.lat',50)
Options<-WeatherMap.set.option(Options,'label.xp',0.49)
Options$ice.points<-50000
Options$wind.vector.lwd<-4
fog.threshold<-exp(1)

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
              180-70*as.numeric(Date-start.date)/as.numeric(fix.date-start.date))
    lat<-50+129*as.numeric(Date-start.date)/as.numeric(fix.date-start.date)
    #if(lat>90) lat<-lat-180
    Options<-WeatherMap.set.option(Options,'pole.lat',lat)    
  }
  return(Options)
}
  

# Make the selected plot

plot.time<-function(c.date,streamlines) {

   year=as.numeric(as.character(years(c.date)))
   month=months(c.date)
   day=days(c.date)
   hour=hours(c.date)
   
    image.name<-'Route.png'
    ifile.name<-image.name

    Options.local<-set.pole(c.date,Options)
    icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                                 version='3.5.1')
    
    png(ifile.name,
                 width=1080,
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
      

      # Plot endurance positions
          w<-seq(1,2851)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(153,15,15,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
      # Plot patience camp positions
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,178,178,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[-w],
                   Latitude=Endurance$V15[-w])
          WeatherMap.draw.obs(ot,Options.local)

     # Plot James Caird positions
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(204,81,81,255,maxColorValue=255))
          ot<-list(Longitude=James_Caird$V16,
                   Latitude=James_Caird$V15)
          WeatherMap.draw.obs(ot,Options.local)
     # Plot Aurora
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(38,15,153,255,maxColorValue=255))
          ot<-list(Longitude=Aurora$V16,
                   Latitude=Aurora$V15)
          WeatherMap.draw.obs(ot,Options.local)
     # Plot Emma
          w<-seq(1,593)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(100,100,100,255,maxColorValue=255))
          ot<-list(Longitude=EmmaYelcho$V16[w],
                   Latitude=EmmaYelcho$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     # Plot Yelcho
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(0,0,0,255,maxColorValue=255))
          ot<-list(Longitude=EmmaYelcho$V16[-w],
                   Latitude=EmmaYelcho$V15[-w])
          WeatherMap.draw.obs(ot,Options.local)

popViewport()
    
    dev.off()
}

plot.time(chron(dates="1915/10/27",times="00:00:00",
                    format=c(dates='y/m/d',times='h:m:s')))

