# R script to plot time-series for Scoresby 1810-18
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2<-read.table('ice_range_1979-2004.out',header=F)
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts4<-read.table('at_range_1979-2004.out',header=F)
sts4$Date<-chron(dates=as.character(sts4$V1),times=as.character(sts4$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1810/01/01','1812/01/01','1814/01/01','1816/01/01','1818/01/01'),format="y/m/d")
ticl = c('1810/01/01','1812/01/01','1814/01/01','1816/01/01','1818/01/01')
      
postscript(file="../figures/All.ps",paper="a4",horizontal=F,family="Helvetica",pointsize=16)
                    
# Sea-ice
pushViewport(viewport(width=1.0,height=0.5,x=0.0,y=0.0,
                      just=c("left","bottom"),name="ice"))
pushViewport(plotViewport(margins=c(3,4,0,1)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-2.5,"lines"))
grid.yaxis(main=T)
grid.text('Sea-ice cover (fraction)',x=unit(-3,"lines"), rot=90)
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V4,'native'),gp=sgb)
popViewport() 
popViewport() 
popViewport() 
              

# AT
pushViewport(viewport(width=1.0,height=0.5,x=0.0,y=0.5,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(1,4,0,1)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(-10,10)))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V5,'native'),gp=sgb)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(5,"native"),gp=sgp)
popViewport() 
popViewport() 
popViewport() 


               
