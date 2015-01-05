# R script to plot AT time-series for Scoresby 1810-18
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts4<-read.table('at_range_1979-2004.out',header=F)
sts4$Date<-chron(dates=as.character(sts4$V1),times=as.character(sts4$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1810/01/01','1812/01/01','1814/01/01','1816/01/01','1818/01/01'),format="y/m/d")
ticl = c('1810/01/01','1812/01/01','1814/01/01','1816/01/01','1818/01/01')
      
postscript(file="../figures/AT.ps",paper="a4",family="Helvetica",pointsize=16)
#png(file="AT.png",width=400,height=300,pointsize=10)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(-45,10)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V5,'native'),gp=sgb)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(3,"native"),gp=sgp)
