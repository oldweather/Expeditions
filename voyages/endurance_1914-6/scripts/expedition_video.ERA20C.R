# Show the Route of the ships along with a Reanalysis comparison

library(GSDF.WeatherMap)
library(chron)
library(GSDF)
library(GSDF.ERA20C)
library(parallel)
library(IMMA)

Endurance<-read.table('Endurance.comparisons.ERA20C')
Endurance$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Endurance$V1,
                          Endurance$V2,Endurance$V3),
                    times=sprintf("%02d:00:00",Endurance$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

Aurora<-read.table('Aurora.comparisons.ERA20C')
Aurora$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Aurora$V1,
                          Aurora$V2,Aurora$V3),
                    times=sprintf("%02d:00:00",Aurora$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

James_Caird<-read.table('James_Caird.comparisons.ERA20C')
James_Caird$Dates<-chron(dates=sprintf("%04d/%02d/%02d",James_Caird$V1,
                          James_Caird$V2,James_Caird$V3),
                    times=sprintf("%02d:00:00",James_Caird$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

EmmaYelcho<-read.table('Emma+Yelcho.comparisons.ERA20C')
EmmaYelcho$Dates<-chron(dates=sprintf("%04d/%02d/%02d",EmmaYelcho$V1,
                          EmmaYelcho$V2,EmmaYelcho$V3),
                    times=sprintf("%02d:00:00",EmmaYelcho$V4),
                       format=c(dates='y/m/d',times='h:m:s'))
lDates<-c(Endurance$Dates,Aurora$Dates,James_Caird$Dates,EmmaYelcho$Dates)
tics=pretty(lDates)
ticl=attr(tics,'labels')

GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))
if(!file.exists(GSDF.cache.dir)) dir.create(GSDF.cache.dir,recursive=TRUE)
Imagedir<-sprintf("%s/images/ITAE.ERA20C/",Sys.getenv('GSCRATCH'))
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
    icec<-ERA20C.get.slice.at.hour('icec',year,month,day,hour)
    
    png(ifile.name,
                 width=1080*16/9,
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
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(Endurance$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,0,0,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(James_Caird$Dates<c.date)  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,55,maxColorValue=255))
          ot<-list(Longitude=James_Caird$V16[w],
                   Latitude=James_Caird$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(James_Caird$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,0,0,255,maxColorValue=255))
          ot<-list(Longitude=James_Caird$V16[w],
                   Latitude=James_Caird$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(Aurora$Dates<c.date)  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,55,maxColorValue=255))
          ot<-list(Longitude=Aurora$V16[w],
                   Latitude=Aurora$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(Aurora$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(0,0,255,255,maxColorValue=255))
          ot<-list(Longitude=Aurora$V16[w],
                   Latitude=Aurora$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      if(Options.local$label != '') {
            WeatherMap.draw.label(Options.local)
      }
      w<-which(EmmaYelcho$Dates<c.date)  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,55,maxColorValue=255))
          ot<-list(Longitude=EmmaYelcho$V16[w],
                   Latitude=EmmaYelcho$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(EmmaYelcho$Dates-c.date)<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(0,0,0,255,maxColorValue=255))
          ot<-list(Longitude=EmmaYelcho$V16[w],
                   Latitude=EmmaYelcho$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      if(Options.local$label != '') {
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
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w)>0) {
            grid.lines(x=unit(Endurance$Dates[w],'native'),
                       y=unit(Endurance$V6[w],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V5[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the James Caird
        w2<-which(James_Caird$Dates<=c.date)  
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w2)>0) {
            grid.lines(x=unit(James_Caird$Dates[w2],'native'),
                       y=unit(James_Caird$V6[w2],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(James_Caird$Dates[w2],'native'),
			 y=unit(James_Caird$V5[w2],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the Emma and Yelcho
        w3<-which(EmmaYelcho$Dates<=c.date)  
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w3)>0) {
            grid.lines(x=unit(EmmaYelcho$Dates[w3],'native'),
                       y=unit(EmmaYelcho$V6[w3],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
	     grid.points(x=unit(EmmaYelcho$Dates[w3],'native'),
			 y=unit(EmmaYelcho$V5[w3],'native'),
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
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w)>0) {
            grid.lines(x=unit(Endurance$Dates[w],'native'),
                       y=unit(Endurance$V9[w],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V8[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the James Caird
        w2<-which(James_Caird$Dates<=c.date)  
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w2)>0) {
            grid.lines(x=unit(James_Caird$Dates[w2],'native'),
                       y=unit(James_Caird$V9[w2],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(James_Caird$Dates[w2],'native'),
			 y=unit(James_Caird$V8[w2],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the Emma and Yelcho
        w3<-which(EmmaYelcho$Dates<=c.date)  
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w3)>0) {
            grid.lines(x=unit(EmmaYelcho$Dates[w3],'native'),
                       y=unit(EmmaYelcho$V9[w3],'native'),
                       gp=gp)
	     gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
	     grid.points(x=unit(EmmaYelcho$Dates[w3],'native'),
			 y=unit(EmmaYelcho$V8[w3],'native'),
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
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w)>0) {
            grid.lines(x=unit(Aurora$Dates[w],'native'),
                       y=unit(Aurora$V6[w],'native'),
                       gp=gp)
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
         gp=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w)>0) {
            grid.lines(x=unit(Aurora$Dates[w],'native'),
                       y=unit(Aurora$V9[w],'native'),
                       gp=gp)
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
e.date<-chron(dates="1916/09/01",times="23:59:59",
          format=c(dates='y/m/d',times='h:m:s'))

Dates = list()
count=1
while(c.date<e.date) {
  for(hour in c(0,6,12,18)) {
     Dates[[count]]<-c.date+hour/24
     count<-count+1
   }
  c.date<-c.date+1
}

#plot.time(Dates[[length(Dates)-100]])

mclapply(Dates,plot.time,mc.cores=8,mc.preschedule=FALSE)
