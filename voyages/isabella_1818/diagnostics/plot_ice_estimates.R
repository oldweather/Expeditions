# R script to plot estimated and HadISST ice-cover time-series for the Isabella
library(grid)
library(chron)

# Read in the data
sts<-read.table('ice_estimates.out',header=F)
sts2<-read.table('ice_range_1979-2004.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1818/05/01','1818/07/01','1818/09/01','1818/11/01'),
      format="y/m/d")
      
postscript(file="../figures/Ice_estimates.ps",paper="a4",family="Helvetica",pointsize=16)
                    
# Make the plot environment
pushViewport(viewport(width=0.80,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,5)))
   
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)-1])),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Sea-ice coverage (fraction)',x=unit(-3,"lines"), rot=90)
# HadISST ranges
   sgn = gpar(col=rgb(0.5,0.5,0.5,1),fill=rgb(0,0,0,1))
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)
   # Legend
   grid.lines(x=unit(c(0.90,0.915),"npc"),y=unit(c(0.1,0.1),"npc"),gp=sgn)
   sgt = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
   grid.text('HadISST max and min 1961-90',just='left',
              x=unit(c(0.95),"npc"),y=unit(c(0.1),"npc"),gp=sgt)
# Speed estimate
   sgp = gpar(col=rgb(0.25,0.25,0.25,1),fill=rgb(0.25,0.25,0.25,1))
   grid.points(x=unit(sts$Date,"native"),
               y=unit(jitter(sts$V6,amount=0.015),'native'),
               pch=20,size=unit(0.75,"native"),gp=sgp)
   # Legend
   grid.points(x=unit(c(0.90),"npc"),y=unit(c(0.15),"npc"),pch=20,
               size=unit(3,"native"),gp=sgp)
   grid.text('Speed estimate',just='left',
              x=unit(c(0.95),"npc"),y=unit(c(0.15),"npc"),gp=sgt)
   
# SST estimate
   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),
               y=unit(jitter(sts$V3,amount=0.015),'native'),
               pch=20,size=unit(0.75,"native"),gp=sgp)
   grid.points(x=unit(c(0.90),"npc"),y=unit(c(0.2),"npc"),pch=20,
               size=unit(3,"native"),gp=sgp)
   grid.text('SST estimate',just='left',
              x=unit(c(0.95),"npc"),y=unit(c(0.2),"npc"),gp=sgt)
# AT estimate
   sgp = gpar(col=rgb(0,1,0,1),fill=rgb(0,1,0,1))
   grid.points(x=unit(sts$Date,"native"),
               y=unit(jitter(sts$V4,amount=0.015),'native'),
               pch=20,size=unit(0.75,"native"),gp=sgp)
   grid.points(x=unit(c(0.90),"npc"),y=unit(c(0.25),"npc"),pch=20,
               size=unit(3,"native"),gp=sgp)
   grid.text('AT estimate',just='left',
              x=unit(c(0.95),"npc"),y=unit(c(0.25),"npc"),gp=sgt)
# ATV estimate
   sgp = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
   grid.points(x=unit(sts$Date,"native"),
               y=unit(jitter(sts$V5,amount=0.015),'native'),
               pch=20,size=unit(0.75,"native"),gp=sgp)
   grid.points(x=unit(c(0.90),"npc"),y=unit(c(0.3),"npc"),pch=20,
               size=unit(3,"native"),gp=sgp)
   grid.text('AT variability estimate',just='left',
              x=unit(c(0.95),"npc"),y=unit(c(0.3),"npc"),gp=sgt)
