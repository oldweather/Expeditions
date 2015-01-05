# R script to plot AT and Ice-cover time-series for the Scotia
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2<-read.table('ice_range_1979-2004.out',header=F)
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = pretty(sts$Date)
ticl = dates(tics)
   
pdf(file="../figures/AT+I.pdf",height=6,width=10,family="Helvetica",pointsize=16)
                 
pushViewport(viewport(width=0.95,height=0.25,x=0.05,y=0.05,
                      just=c("left","bottom"),name="ice"))
pushViewport(plotViewport(margins=c(2,3,0,3)))
pushViewport(dataViewport(as.numeric(sts$Date),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.yaxis(main=F,at=c(0,1))
grid.text('Sea-ice',x=unit(1.08,"npc"), rot=90)
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V5,'native'),gp=sgb)
popViewport() 
popViewport() 
popViewport() 
              
pushViewport(viewport(width=0.95,height=0.75,x=0.05,y=0.25,
                      just=c("left","bottom"),name="at"))
pushViewport(plotViewport(margins=c(0,3,2,3)))
pushViewport(dataViewport(as.numeric(sts$Date),c(-20,30)))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V8,'native'),gp=sgb)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(1,"native"),gp=sgp)
popViewport() 
popViewport() 
popViewport()

