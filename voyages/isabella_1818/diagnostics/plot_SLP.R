# R script to plot SLP time-series for the Isabella
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts5<-read.table('pre_range_1979-2004.out',header=F)
sts5$Date<-chron(dates=as.character(sts5$V1),times=as.character(sts5$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1818/05/01','1818/07/01','1818/09/01','1818/11/01'),
      format="y/m/d")
      
postscript(file="../figures/SLP.ps",paper="a4",family="Helvetica",pointsize=16)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(970,1030)))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Sea-level Pressure (hPa)',x=unit(-4,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts3$Date,"native"),y=unit(sts3$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts3$Date,"native"),y=unit(sts3$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V6,'native'),gp=sgb)
   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V5,'native'),pch=20,
               size=unit(2,"native"),gp=sgp)
