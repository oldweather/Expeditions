# R script to plot SST and Ice-cover time-series for the Isabella
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2<-read.table('ice_range_1961-1990.out',header=F)
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts3<-read.table('sst_range_1979-2004.out',header=F)
sts3$Date<-chron(dates=as.character(sts3$V1),times=as.character(sts3$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1818/05/01','1818/07/01','1818/09/01','1818/11/01'),
      format="y/m/d")
      
postscript(file="../figures/SST+I.ps",paper="a4",family="Helvetica",pointsize=16)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.25,x=0.05,y=0.05,
                      just=c("left","bottom"),name="ice"))
pushViewport(plotViewport(margins=c(2,2,0,5)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-2.5,"lines"))
grid.yaxis(main=F)
grid.text('Sea-ice cover (fraction)',x=unit(1.1,"npc"), rot=90)
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V4,'native'),gp=sgb)
popViewport() 
popViewport() 
popViewport() 
              
pushViewport(viewport(width=0.95,height=0.7,x=0.05,y=0.3,
                      just=c("left","bottom"),name="sst"))
pushViewport(plotViewport(margins=c(0,2,2,5)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(-5,10)))
grid.yaxis(main=T)
grid.text('Sea Surface Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts3$Date,"native"),y=unit(sts3$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts3$Date,"native"),y=unit(sts3$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V6,'native'),gp=sgb)
   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V5,'native'),pch=20,
               size=unit(2,"native"),gp=sgp)
