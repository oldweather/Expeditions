# R script to plot speed and ice-cover time-series for the Isabella
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts2<-read.table('ice_range_1979-2004.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1818/05/01','1818/07/01','1818/09/01','1818/11/01'),
      format="y/m/d")
      
postscript(file="../figures/Ice.ps",paper="a4",family="Helvetica",pointsize=16)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,5)))
   
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=F)
grid.text('Sea-ice coverage (fraction)',x=unit(1.1,"npc"), rot=90)
   sgn = gpar(col=rgb(0.5,0.5,0.5,1),fill=rgb(0,0,0,1))
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)

popViewport()
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(0,5)))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
grid.text('Average speed (m/s)',x=unit(-4,"lines"),rot=90,gp=sgp)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V3,'native'),pch=20,
               size=unit(2,"native"),gp=sgp)

