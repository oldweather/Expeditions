# Show the Route of the ships along with a Reanalysis comparison

library(GSDF.WeatherMap)
library(chron)
library(GSDF)
library(GSDF.TWCR)
library(parallel)
library(IMMA)

Endurance<-read.table('Endurance.comparisons')
Endurance.4<-read.table('Endurance.comparisons.354')
Endurance$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Endurance$V1,
                          Endurance$V2,Endurance$V3),
                    times=sprintf("%02d:00:00",Endurance$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

Aurora<-read.table('Aurora.comparisons')
Aurora.4<-read.table('Aurora.comparisons.354')
Aurora$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Aurora$V1,
                          Aurora$V2,Aurora$V3),
                    times=sprintf("%02d:00:00",Aurora$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

James_Caird<-read.table('James_Caird.comparisons')
James_Caird.4<-read.table('James_Caird.comparisons.354')
James_Caird$Dates<-chron(dates=sprintf("%04d/%02d/%02d",James_Caird$V1,
                          James_Caird$V2,James_Caird$V3),
                    times=sprintf("%02d:00:00",James_Caird$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

EmmaYelcho<-read.table('Emma+Yelcho.comparisons')
EmmaYelcho.4<-read.table('Emma+Yelcho.comparisons.354')
EmmaYelcho$Dates<-chron(dates=sprintf("%04d/%02d/%02d",EmmaYelcho$V1,
                          EmmaYelcho$V2,EmmaYelcho$V3),
                    times=sprintf("%02d:00:00",EmmaYelcho$V4),
                       format=c(dates='y/m/d',times='h:m:s'))
lDates<-c(Endurance$Dates,Aurora$Dates,James_Caird$Dates,EmmaYelcho$Dates)
tics=pretty(lDates)
ticl=attr(tics,'labels')

GSDF.cache.dir<-sprintf("%s/GSDF.cache",Sys.getenv('GSCRATCH'))
if(!file.exists(GSDF.cache.dir)) dir.create(GSDF.cache.dir,recursive=TRUE)
Imagedir<-sprintf("%s/images/ITAE.streamlines/",Sys.getenv('GSCRATCH'))
if(!file.exists(Imagedir)) dir.create(Imagedir,recursive=TRUE)

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
    Options<-WeatherMap.set.option(Options,'pole.lat',
              50+129*as.numeric(Date-start.date)/as.numeric(fix.date-start.date))    
  }
  return(Options)
}
  
# Rotate a set of streamlines to a new pole
rotate.streamlines<-function(s,pole.lat,pole.lon) {
   if(is.null(s)) return(NULL)
   if(!is.null(s$pole.lat)) {
     nl<-GSDF.rg.to.ll(s$y,s$x,s$pole.lat,s$pole.lon)
     s$x[]<-nl$lon
     s$y[]<-nl$lat
   }
   nl<-GSDF.ll.to.rg(s$y,s$x,pole.lat,pole.lon)
   s$x[]<-nl$lon
   s$y[]<-nl$lat
   s$pole.lat<-pole.lat
   s$pole.lon<-pole.lon
   return(s)
}

make.streamlines<-function(year,month,day,hour,pole.lat,pole.lon,streamlines=NULL) {

    sf.name<-sprintf("%s/streamlines.%04d-%02d-%02d:%02d.rd",
                           Imagedir,year,month,day,hour)
    if(file.exists(sf.name) && file.info(sf.name)$size>500000) {
       load(sf.name)
       return(s)
    }
    print(sprintf("%04d-%02d-%02d:%02d - %s",year,month,day,hour,
                   Sys.time()))

    uwnd<-TWCR.get.slice.at.hour('uwnd.10m',year,month,day,hour,version=version)
    vwnd<-TWCR.get.slice.at.hour('vwnd.10m',year,month,day,hour,version=version)
    t.actual<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,version=version)
    t.normal<-t.actual
    t.normal$data[]<-rep(283,length(t.normal$data))
    #if(!is.null(streamlines)) {
    #   streamlines<-rotate.streamlines(streamlines,pole.lat,pole.lon)
    #}
    s<-WeatherMap.make.streamlines(streamlines,uwnd,vwnd,t.actual,t.normal,Options.local)
    save(year,month,day,hour,s,file=sf.name)
    gc(verbose=FALSE)
    return(s)

}

# Make the selected plot

plot.time<-function(c.date,streamlines) {

   year=as.numeric(as.character(years(c.date)))
   month=months(c.date)
   day=days(c.date)
   hour=hours(c.date)
   
    image.name<-sprintf("%04d-%02d-%02d:%02d.png",year,month,day,hour)
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    if(file.exists(ifile.name) && file.info(ifile.name)$size>1000) return()
    print(sprintf("%04d-%02d-%02d:%02d",year,month,day,hour))

    Options.local<-set.pole(c.date,Options)
    prmsl<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version=version)
    prmsl.spread<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version=version,
                                              type='spread')
    prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
                                         version='3.4.1',type='standard.deviation')
    prmsl.normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.4.1',
                                             type='normal')
    fog<-TWCR.relative.entropy(prmsl.normal,prmsl.sd,prmsl,prmsl.spread)
    fog$data[]<-1-pmin(fog.threshold,pmax(0,fog$data))/fog.threshold
    prate<-NULL
    if(Options$show.precipitation) {
       prate<-TWCR.get.slice.at.hour('prate',year,month,day,hour,version=version)
     }
    icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,
                                 version='3.5.1')
    #sst<-TWCR.get.slice.at.hour('sst',year,month,day,hour,
    #                             version='3.5.1')
    #sst.normal<-TWCR.get.slice.at.hour('sst',year,month,day,hour,version='3.4.1',
    #                                         type='normal')
    #sst$data[]<-sst$data-sst.normal$data
    
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

      #Draw.temperature(sst,Options.local)     

      ip<-WeatherMap.rectpoints(Options.local$ice.points,Options.local)
      WeatherMap.draw.ice(ip$lat,ip$lon,icec,Options.local)
      WeatherMap.draw.land(NULL,Options.local)
      

      obs<-TWCR.get.obs(year,month,day,hour,version='3.5.4')
      w<-which(obs$Longitude>180)
      obs$Longitude[w]<-obs$Longitude[w]-360
      Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                rgb(255,215,0,255,maxColorValue=255))
      Options.local<-WeatherMap.set.option(Options.local,'obs.size',0.5)
      WeatherMap.draw.obs(obs,Options.local)
      WeatherMap.draw.streamlines(streamlines,Options.local)
      WeatherMap.draw.fog(fog,Options.local)
      Options.local<-WeatherMap.set.option(Options.local,'obs.size',1.5)
      w<-which(Endurance$Dates<(c.date+1))  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(as.numeric(Endurance$Dates-c.date))<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,0,0,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(James_Caird$Dates<(c.date+1))  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,255,maxColorValue=255))
          ot<-list(Longitude=James_Caird$V16[w],
                   Latitude=James_Caird$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(as.numeric(James_Caird$Dates-c.date))<1)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(255,0,0,255,maxColorValue=255))
          ot<-list(Longitude=James_Caird$V16[w],
                   Latitude=James_Caird$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(Aurora$Dates<(c.date+1))  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,255,maxColorValue=255))
          ot<-list(Longitude=Aurora$V16[w],
                   Latitude=Aurora$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(as.numeric(Aurora$Dates-c.date))<1)
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
      w<-which(EmmaYelcho$Dates<(c.date+1))  
      if(length(w)>0) {
          Options.local<-WeatherMap.set.option(Options.local,'obs.colour',
                                   rgb(200,200,200,255,maxColorValue=255))
          ot<-list(Longitude=EmmaYelcho$V16[w],
                   Latitude=EmmaYelcho$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
     }
      w<-which(abs(as.numeric(EmmaYelcho$Dates-c.date))<1)
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
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         gp2=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
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
	     for(i in seq_along(Endurance.4$V1[w])) {
		x<-c(Endurance$Dates[i]-0.125,Endurance$Dates[i]+0.125,
		     Endurance$Dates[i]+0.125,Endurance$Dates[i]-0.125)
		y<-c(Endurance.4$V6[i]-(Endurance.4$V7[i])*2,
		     Endurance.4$V6[i]-(Endurance.4$V7[i])*2,
		     Endurance.4$V6[i]+(Endurance.4$V7[i])*2,
		     Endurance.4$V6[i]+(Endurance.4$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V5[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the James Caird
        w2<-which(James_Caird$Dates<=c.date)  
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         gp2=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
         if(length(w2)>0) {
	     for(i in seq_along(James_Caird$V1[w2])) {
		x<-c(James_Caird$Dates[i]-0.125,James_Caird$Dates[i]+0.125,
		     James_Caird$Dates[i]+0.125,James_Caird$Dates[i]-0.125)
		y<-c(James_Caird$V6[i]-(James_Caird$V7[i])*2,
		     James_Caird$V6[i]-(James_Caird$V7[i])*2,
		     James_Caird$V6[i]+(James_Caird$V7[i])*2,
		     James_Caird$V6[i]+(James_Caird$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     for(i in seq_along(James_Caird.4$V1[w2])) {
		x<-c(James_Caird$Dates[i]-0.125,James_Caird$Dates[i]+0.125,
		     James_Caird$Dates[i]+0.125,James_Caird$Dates[i]-0.125)
		y<-c(James_Caird.4$V6[i]-(James_Caird.4$V7[i])*2,
		     James_Caird.4$V6[i]-(James_Caird.4$V7[i])*2,
		     James_Caird.4$V6[i]+(James_Caird.4$V7[i])*2,
		     James_Caird.4$V6[i]+(James_Caird.4$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(James_Caird$Dates[w2],'native'),
			 y=unit(James_Caird$V5[w2],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the Emma and Yelcho
        w3<-which(EmmaYelcho$Dates<=c.date)  
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w3)>0) {
	     for(i in seq_along(EmmaYelcho$V1[w3])) {
		x<-c(EmmaYelcho$Dates[i]-0.125,EmmaYelcho$Dates[i]+0.125,
		     EmmaYelcho$Dates[i]+0.125,EmmaYelcho$Dates[i]-0.125)
		y<-c(EmmaYelcho$V6[i]-(EmmaYelcho$V7[i])*2,
		     EmmaYelcho$V6[i]-(EmmaYelcho$V7[i])*2,
		     EmmaYelcho$V6[i]+(EmmaYelcho$V7[i])*2,
		     EmmaYelcho$V6[i]+(EmmaYelcho$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     for(i in seq_along(EmmaYelcho.4$V1[w3])) {
		x<-c(EmmaYelcho$Dates[i]-0.125,EmmaYelcho$Dates[i]+0.125,
		     EmmaYelcho$Dates[i]+0.125,EmmaYelcho$Dates[i]-0.125)
		y<-c(EmmaYelcho.4$V6[i]-(EmmaYelcho.4$V7[i])*2,
		     EmmaYelcho.4$V6[i]-(EmmaYelcho.4$V7[i])*2,
		     EmmaYelcho.4$V6[i]+(EmmaYelcho.4$V7[i])*2,
		     EmmaYelcho.4$V6[i]+(EmmaYelcho.4$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
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
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         gp2=gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1))
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
	     for(i in seq_along(Endurance.4$V1[w])) {
		x<-c(Endurance$Dates[i]-0.125,Endurance$Dates[i]+0.125,
		     Endurance$Dates[i]+0.125,Endurance$Dates[i]-0.125)
		y<-c(Endurance.4$V9[i]-(Endurance.4$V10[i])*2,
		     Endurance.4$V9[i]-(Endurance.4$V10[i])*2,
		     Endurance.4$V9[i]+(Endurance.4$V10[i])*2,
		     Endurance.4$V9[i]+(Endurance.4$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(Endurance$Dates[w],'native'),
			 y=unit(Endurance$V8[w],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the James Caird
        w2<-which(James_Caird$Dates<=c.date)  
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w2)>0) {
	     for(i in seq_along(James_Caird$V1[w2])) {
		x<-c(James_Caird$Dates[i]-0.125,James_Caird$Dates[i]+0.125,
		     James_Caird$Dates[i]+0.125,James_Caird$Dates[i]-0.125)
		y<-c(James_Caird$V9[i]-(James_Caird$V10[i])*2,
		     James_Caird$V9[i]-(James_Caird$V10[i])*2,
		     James_Caird$V9[i]+(James_Caird$V10[i])*2,
		     James_Caird$V9[i]+(James_Caird$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     for(i in seq_along(James_Caird.4$V1[w2])) {
		x<-c(James_Caird$Dates[i]-0.125,James_Caird$Dates[i]+0.125,
		     James_Caird$Dates[i]+0.125,James_Caird$Dates[i]-0.125)
		y<-c(James_Caird.4$V9[i]-(James_Caird.4$V10[i])*2,
		     James_Caird.4$V9[i]-(James_Caird.4$V10[i])*2,
		     James_Caird.4$V9[i]+(James_Caird.4$V10[i])*2,
		     James_Caird.4$V9[i]+(James_Caird.4$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
	     gp=gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
	     grid.points(x=unit(James_Caird$Dates[w2],'native'),
			 y=unit(James_Caird$V8[w2],'native'),
			 size=unit(0.005,'npc'),
			 pch=20,
			 gp=gp)
         }
        # Add the Emma and Yelcho
        w3<-which(EmmaYelcho$Dates<=c.date)  
         gp=gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1))
         if(length(w3)>0) {
	     for(i in seq_along(EmmaYelcho$V1[w3])) {
		x<-c(EmmaYelcho$Dates[i]-0.125,EmmaYelcho$Dates[i]+0.125,
		     EmmaYelcho$Dates[i]+0.125,EmmaYelcho$Dates[i]-0.125)
		y<-c(EmmaYelcho$V9[i]-(EmmaYelcho$V10[i])*2,
		     EmmaYelcho$V9[i]-(EmmaYelcho$V10[i])*2,
		     EmmaYelcho$V9[i]+(EmmaYelcho$V10[i])*2,
		     EmmaYelcho$V9[i]+(EmmaYelcho$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp)
	      }
	     for(i in seq_along(EmmaYelcho.4$V1[w3])) {
		x<-c(EmmaYelcho$Dates[i]-0.125,EmmaYelcho$Dates[i]+0.125,
		     EmmaYelcho$Dates[i]+0.125,EmmaYelcho$Dates[i]-0.125)
		y<-c(EmmaYelcho.4$V9[i]-(EmmaYelcho.4$V10[i])*2,
		     EmmaYelcho.4$V9[i]-(EmmaYelcho.4$V10[i])*2,
		     EmmaYelcho.4$V9[i]+(EmmaYelcho.4$V10[i])*2,
		     EmmaYelcho.4$V9[i]+(EmmaYelcho.4$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
	      }
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
	     for(i in seq_along(Aurora.4$V1[w])) {
		x<-c(Aurora$Dates[i]-0.125,Aurora$Dates[i]+0.125,
		     Aurora$Dates[i]+0.125,Aurora$Dates[i]-0.125)
		y<-c(Aurora.4$V6[i]-(Aurora.4$V7[i])*2,
		     Aurora.4$V6[i]-(Aurora.4$V7[i])*2,
		     Aurora.4$V6[i]+(Aurora.4$V7[i])*2,
		     Aurora.4$V6[i]+(Aurora.4$V7[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
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
	     for(i in seq_along(Aurora.4$V1[w])) {
		x<-c(Aurora$Dates[i]-0.125,Aurora$Dates[i]+0.125,
		     Aurora$Dates[i]+0.125,Aurora$Dates[i]-0.125)
		y<-c(Aurora.4$V9[i]-(Aurora.4$V10[i])*2,
		     Aurora.4$V9[i]-(Aurora.4$V10[i])*2,
		     Aurora.4$V9[i]+(Aurora.4$V10[i])*2,
		     Aurora.4$V9[i]+(Aurora.4$V10[i])*2)
		grid.polygon(x=unit(x,'native'),
			     y=unit(y,'native'),
			  gp=gp2)
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
e.date<-chron(dates="1916/09/01",times="23:59:59",
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

#plot.time(Dates[[2000]])

s<-NULL
for(c.date in Dates[1:4800]) {

    year<-as.numeric(as.character(years(c.date)))
    month<-months(c.date)
    day<-days(c.date)
    hour<-as.integer(hours(c.date))

    # serial component - streamlines evolve from hour to hour
    Options.local<-set.pole(c.date,Options)
    s<-make.streamlines(year,month,day,hour,Options.local$pole.lat,
                        Options.local$pole.lon,streamlines=s)

    image.name<-sprintf("%04d-%02d-%02d:%02d.png",year,month,day,hour)
    ifile.name<-sprintf("%s/%s",Imagedir,image.name)
    if(file.exists(ifile.name) && file.info(ifile.name)$size>0) next
    # Each plot in a seperate parallel process
    mcparallel(plot.time(c.date,s))
    if(hour==12) mccollect(wait=TRUE)

}
mccollect()
