#!/usr/common/software/R/3.2.2/hsw/intel/bin/Rscript --no-save

# Pressures and temperatures from 3.5.4 around an isolated Endurance ob.

# Compares 6 different ensemble members

library(GSDF.TWCR)
library(GSDF.WeatherMap)
library(parallel)
library(chron)

Year<-1915
Month<-5
Day<-1
Hour<-3
n.total<-0
version<-'3.5.1'
fog.threshold<-exp(1)
screen.width<-1080*16/9
screen.height<-1080
#members<-c(1,38,39,47,21,24) # Max errors in at,v.10m, and prmsl
members<-c(53,20,34,52,7,31) # Max errors in at,v.10m, and prmsl
lat.range<-30
lon.range<-30

Endurance<-read.table('../Endurance.comparisons')
Endurance.4<-read.table('../Endurance.comparisons.354')
Endurance$Dates<-chron(dates=sprintf("%04d/%02d/%02d",Endurance$V1,
                          Endurance$V2,Endurance$V3),
                    times=sprintf("%02d:00:00",Endurance$V4),
                       format=c(dates='y/m/d',times='h:m:s'))

Imagedir<-'.'

c.date<-chron(dates=sprintf("%04d/%02d/%02d",Year,Month,Day),
            times=sprintf("%02d:%02d:00",as.integer(Hour),as.integer(Hour%%1*60)),
            format=c(dates='y/m/d',times='h:m:s'))
w.d<-which(abs(as.numeric(Endurance$Dates-c.date))<0.01)
base.pressure.anomaly<-Endurance$V5[w.d[1]]-Endurance.4$V6[w.d[1]]

lat.d<-Endurance$V15[w.d[1]]
lon.d<-Endurance$V16[w.d[1]]

get.values.by.member<-function(variable,year,month,day,hour,lat.d,lon.d) {
  
       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version='3.5.4')
       res<-rep(NA,56)
       for(member in seq(1,56)) {
          m<-GSDF.select.from.1d(t,'ensemble',member)
          res[member]<-GSDF.interpolate.ll(m,lat.d,lon.d)
        }
       gc()
       return(res)
  }
prmsl.d<-get.values.by.member('prmsl',Year,Month,Day,Hour,lat.d,lon.d)
air.2m.d<-get.values.by.member('air.2m',Year,Month,Day,Hour,lat.d,lon.d)
uwnd.10m.d<-get.values.by.member('uwnd.10m',Year,Month,Day,Hour,lat.d,lon.d)
vwnd.10m.d<-get.values.by.member('vwnd.10m',Year,Month,Day,Hour,lat.d,lon.d)

wind.direction<-function(u,v) {
  # From u,v get an angle (degrees) clockwise from North from u,v
  u<- -u
  v<- -v # Want the direction the wind comes from
  a<-NA
  if(u>0 && v>0) a<-atan2(v,u)*180/pi
  if(u>0 && v==0) a<-90
  if(u>0 && v<0) a<-90-(atan2(v,u)*180/pi)
  if(u==0 && v>0) a<-0
  if(u==0 && v<0) a<-180
  if(u<0 && v<0)  a<-90-(atan2(v,u)*180/pi)
  if(u<0 && v==0) a<-270
  if(u<0 && v>0)  a<-450-(atan2(v,u)*180/pi)
  return(a)
}

wind.direction.error<-function(u,v,obs) {
  a<-wind.direction(u,v)
  result<-obs-a
  # adjust for rotational symmetry
  if(result>180) result<-result-360
  if(result< -180) result<-result+360
  return(result)
}

wde<-rep(NA,length(uwnd.10m.d))
for(i in seq_along(wde)) {
  wde[i]<-wind.direction.error(uwnd.10m.d[i],vwnd.10m.d[i],203)
}

# To display n members simultaniously on the screen, specify a layout
# Need screen width and height in pixels, members to plot,
# aspect ratio of region to plot
Layout<-function(x,y,members,aspect=1.33,border=0.05) {
  n<-length(members)
  layout<-c(n,1)
  scale<-min(x/layout[1],y/layout[2]*aspect)
  area.fraction<-n*aspect*scale*scale/(x*y)
  while(TRUE) {
    l2<-layout[2]+1
    l1<-ceiling(n/(layout[2]+1))
    s2<-min(x/l1,y/l2*aspect)
    a2<-n*aspect*s2*s2/(x*y)
    if(a2<=area.fraction) break
    layout[2]<-l2
    layout[1]<-l1
    scale<-s2
    area.fraction<-a2
  }
    viewports<-list()
    vp<-1
    x.range<-(1/layout[1]*(1-border))*x
    y.range<-(1/layout[2]*(1-border))*y
    for(j in layout[2]:1) {
        y.offset<-((j-1)/layout[2]+border/4)*y
        for(i in 1:layout[1]) {
            x.offset<-((i-1)/layout[1]+border/4)*x
            viewports[[vp]]<-c(x.offset,y.offset,x.range,y.range)
            vp<-vp+1
        }
    }
  
  n.l<-list(nx=layout[1],ny=layout[2],contents=members,
            viewports=viewports)
  return(n.l)
}

member.layout<-Layout(screen.width,screen.height,members,lat.range/lon.range)

Options<-WeatherMap.set.option(NULL)

Options<-WeatherMap.set.option(NULL)
Options<-WeatherMap.set.option(Options,'show.mslp',T)
Options<-WeatherMap.set.option(Options,'show.ice',T)
Options<-WeatherMap.set.option(Options,'show.obs',T)
Options<-WeatherMap.set.option(Options,'show.fog',T)
Options<-WeatherMap.set.option(Options,'show.precipitation',T)
Options<-WeatherMap.set.option(Options,'temperature.range',12)
Options<-WeatherMap.set.option(Options,'obs.size',1)
Options<-WeatherMap.set.option(Options,'obs.colour',rgb(255,215,0,255,
                                                         maxColorValue=255))
Options<-WeatherMap.set.option(Options,'land.colour',rgb(255,255,255,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'ice.colour',rgb(255,255,255,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'sea.colour',rgb(200,200,200,255,
                                                       maxColorValue=255))
Options<-WeatherMap.set.option(Options,'lat.min',-lat.range/2)
Options<-WeatherMap.set.option(Options,'lat.max',lat.range/2)
Options<-WeatherMap.set.option(Options,'lon.min',-lon.range/2)
Options<-WeatherMap.set.option(Options,'lon.max',lon.range/2)
Options<-WeatherMap.set.option(Options,'pole.lon',130)
Options<-WeatherMap.set.option(Options,'pole.lat',165)

Options$precip.points<-100000
Options$mslp.base=0                    # Base value for anomalies
Options$mslp.range=50000                    # Anomaly for max contour
Options$mslp.step=500                       # Smaller -more contours
Options$mslp.tpscale=500                    # Smaller -contours less transparent
Options$mslp.lwd=1
land<-WeatherMap.get.land(Options)

get.member.at.hour<-function(variable,year,month,day,hour,member) {
  
       t<-TWCR.get.members.slice.at.hour(variable,year,month,day,
                                  hour,version='3.5.4')
       t<-GSDF.select.from.1d(t,'ensemble',member)
       gc()
       return(t)
  }

Draw.temperature<-function(temperature,Options,Trange=10) {
    
    Options.local<-Options
    Options.local$fog.min.transparency<-0.5
    tplus<-temperature
    tplus$data[]<-pmax(1,pmin(Trange,tplus$data))/Trange
    Options.local$fog.colour<-c(1,0,0)
    WeatherMap.draw.fog(tplus,Options.local)
    tminus<-temperature
    tminus$data[]<-tminus$data*-1
    tminus$data[]<-pmax(1,pmin(Trange,tminus$data))/Trange
    Options.local$fog.colour<-c(0,0,1)
    WeatherMap.draw.fog(tminus,Options.local)
  }


Draw.pressure<-function(mslp,Options,colour=c(0,0,0)) {
  
    M<-GSDF.WeatherMap:::WeatherMap.rotate.pole(mslp,Options)
    lats<-M$dimensions[[GSDF.find.dimension(M,'lat')]]$values
    longs<-M$dimensions[[GSDF.find.dimension(M,'lon')]]$values
      # Need particular data format for contourLines
    if(lats[2]<lats[1] || longs[2]<longs[1] || max(longs)> 180 ) {
      if(lats[2]<lats[1]) lats<-rev(lats)
      if(longs[2]<longs[1]) longs<-rev(longs)
      longs[longs>180]<-longs[longs>180]-360
      longs<-sort(longs)
      M2<-M
      M2$dimensions[[GSDF.find.dimension(M,'lat')]]$values<-lats
      M2$dimensions[[GSDF.find.dimension(M,'lon')]]$values<-longs
      M<-GSDF.regrid.2d(M,M2)
    }
    z<-matrix(data=M$data,nrow=length(longs),ncol=length(lats))
    contour.levels<-seq(Options$mslp.base-Options$mslp.range,
                        Options$mslp.base+Options$mslp.range,
                        Options$mslp.step)
    w<-which(contour.levels<base.pressure.anomaly)
    contour.levels<-c(contour.levels[w],base.pressure.anomaly,contour.levels[-w])
    lines<-contourLines(longs,lats,z,
                         levels=contour.levels)
    if(!is.na(lines) && length(lines)>0) {
       for(i in seq(1,length(lines))) {
           tp<-min(1,(abs(lines[[i]]$level-Options$mslp.base)/
                      Options$mslp.tpscale))
           lt<-2
           lwd<-1
           if(lines[[i]]$level<=Options$mslp.base) {
               lt<-1
               lwd<-1
           }
           gp<-gpar(col=rgb(colour[1],colour[2],colour[3],tp),
                               lwd=Options$mslp.lwd*lwd,lty=lt)
           if(abs(lines[[i]]$level-base.pressure.anomaly)<1) {
              gp<-gpar(col=rgb(255,215,0,255,maxColorValue=255),
                               lwd=Options$mslp.lwd*lwd,lty=lt)
            }
           grid.lines(x=unit(lines[[i]]$x,'native'),
                      y=unit(lines[[i]]$y,'native'),
                      gp=gp)
       }
    }
  }

plot.hour<-function(n.count) {    
  
      n.date<-c.date+n.count/(24*3) # 20-minute timesteps
      year<-as.numeric(as.character(years(n.date)))
      month<-months(n.date)
      day<-days(n.date)
      hour<-hours(n.date)+minutes(n.date)/60

      image.name<-sprintf("by_member_%04d-%02d-%02d:%02d:%02d.png",year,month,day,as.integer(hour),
                                                         as.integer(hour%%1*60))
  
      ifile.name<-sprintf("%s/%s",Imagedir,image.name)
      #if(file.exists(ifile.name) && file.info(ifile.name)$size>0) return()
  
      t2m<-get.member.at.hour('air.2m',year,month,day,hour,1) # only for regridding
      t2m.normal<-TWCR.get.slice.at.hour('air.2m',year,month,day,hour,version='3.4.1',
                                               type='normal')
      t2m.normal<-GSDF.regrid.2d(t2m.normal,t2m)
      #prmsl.sd<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,
      #                                     version='3.4.1',type='standard.deviation')
      #prmsl.spread<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version=versions[vn],
      #					  type='spread')
      #fog<-TWCR.relative.entropy(prmsl.normal,prmsl.sd,prmsl,prmsl.spread)
      #fog$data[]<-1-pmin(fog.threshold,pmax(0,fog$data))/fog.threshold
      prmsl<-get.member.at.hour('prmsl',year,month,day,hour,1) # only for regridding
      prmsl.normal<-TWCR.get.slice.at.hour('prmsl',year,month,day,hour,version='3.4.1',
                                               type='normal')
      prmsl.normal<-GSDF.regrid.2d(prmsl.normal,prmsl)
         #obs<-TWCR.get.obs(year,month,day,hour,version='3.5.1')
         #w<-which(obs$Longitude>180)
         #obs$Longitude[w]<-obs$Longitude[w]-360
      icec<-TWCR.get.slice.at.hour('icec',year,month,day,hour,version='3.5.1')
  
  
       png(ifile.name,
               width=screen.width,
               height=screen.height,
               bg='white',
               pointsize=24,
               type='cairo')
  
      for(vn in seq_along(members)) {
  
  	prmsl<-get.member.at.hour('prmsl',year,month,day,hour,members[vn])
  	t2m<-get.member.at.hour('air.2m',year,month,day,hour,members[vn])
  	#prate<-get.member.at.hour('prate',year,month,day,hour,members[vn])
  	prmsl$data[]<-as.vector(prmsl$data)-as.vector(prmsl.normal$data)
  	t2m$data[]<-as.vector(t2m$data)-as.vector(t2m.normal$data)
  
  	   pushViewport(viewport(width=unit(member.layout$viewports[[vn]][3]/screen.width,'npc'),
                                 height=unit(member.layout$viewports[[vn]][4]/screen.height,'npc'),
                                 x=unit(member.layout$viewports[[vn]][1]/screen.width,'npc'),
                                 y=unit(member.layout$viewports[[vn]][2]/screen.height,'npc'),
  			      just=c("left","bottom"),clip='on'))
  
  	   pushViewport(dataViewport(c(Options$lon.min,Options$lon.max),
  				     c(Options$lat.min,Options$lat.max),
  				      extension=0))
                grid.polygon(x=unit(c(0,1,1,0),'npc'),y=unit(c(0,0,1,1),'npc'),
                             gp=gpar(col=Options$sea.colour,fill=Options$sea.colour))
  	      ip<-WeatherMap.rectpoints(Options$ice.points,Options)
  	      WeatherMap.draw.ice(ip$lat,ip$lon,icec,Options)
  	      WeatherMap.draw.land(land,Options)
  
      Draw.temperature(t2m,Options)
      w<-which(abs(as.numeric(Endurance$Dates-n.date))<0.01)
      if(length(w)>0) {
          w<-max(w)
          Options.local<-WeatherMap.set.option(Options,'obs.colour',
                                   rgb(255,215,0,255,maxColorValue=255))
          ot<-list(Longitude=Endurance$V16[w],
                   Latitude=Endurance$V15[w])
          WeatherMap.draw.obs(ot,Options.local)
        }
  	Draw.pressure(prmsl,Options,colour=c(0,0,0))
  	    #WeatherMap.draw.precipitation(prate,Options)
  	    #WeatherMap.draw.fog(fog,Options)
  
  	    grid.text(as.character(members[vn]),x=unit(0.01,'npc'),y=unit(0.99,'npc'),just=c('left','top'),
                                   gp=gpar(lex=0.5))
  	    #WeatherMap.draw.label(Options)
  	 upViewport()
  	 upViewport()
  
      }
      Options$land.colour<-'white'
      Options$label<-sprintf("%04d-%02d-%02d:%02d",year,month,day,as.integer(hour))
      WeatherMap.draw.label(Options)
  
      dev.off()
  }

plot.hour(0)
