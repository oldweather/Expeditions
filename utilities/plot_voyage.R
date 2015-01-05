# Make a synthesis figure for an expedition
library(grid)
library(chron)
library(lattice)
library(maps)

# Load the map functions
source("../../../../scripts/sr.map.R")
gp_red   = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
gp_black = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lex=2)
gp_grey  = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0.7,0.7,0.7,1),lex=1)

# Read in the data
sts<-read.table('../scripts/ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),
                           format=c(dates = "y/m/d", times = "h:m:s"))
tics<-pretty(sts$Date)
ticl<-attr(tics,'labels')
      
pdf(file="../figures/voyage.pdf",width=11.7,height=8.3,
    family="Helvetica",pointsize=12)

# Estimate a point size for the plots
pointSize <- min(4.0/length(sts$Date),0.05)
                    
# Four seperate plots - route, AT, SLP, SST/WS - each in its own viewport
pushViewport(viewport(width=0.4,height=0.4,x=0.05,y=0.6,
                      just=c("left","bottom"),name="vp_map"))
upViewport(0)
pushViewport(viewport(width=0.4,height=0.4,x=0.55,y=0.6,
                     just=c("left","bottom"),name="vp_slp"))
upViewport(0)
pushViewport(viewport(width=0.4,height=0.4,x=0.55,y=0.1,
                      just=c("left","bottom"),name="vp_at"))
upViewport(0)
pushViewport(viewport(width=0.4,height=0.4,x=0.05,y=0.1,
                      just=c("left","bottom"),name="vp_sst"))
upViewport(0)

# Draw the map
sr.map.internal.wm <- map('world',interior=FALSE,plot=FALSE)
is.na(sr.map.internal.wm$x[8836])=T  # Remove Antarctic bug
# Prune everything outside the viewport
for(i in seq(1,length(sr.map.internal.wm$x))) {
    if ( is.na(sr.map.internal.wm$x[i]) 
        || (is.na(sr.map.internal.wm$y[i]))
        || (sr.map.internal.wm$x[i]< -180)
        || (sr.map.internal.wm$x[i]> 180)
        || (sr.map.internal.wm$y[i]< -90)
        || (sr.map.internal.wm$y[i]> 90)) {
         is.na(sr.map.internal.wm$x[i]) = T
         is.na(sr.map.internal.wm$y[i]) = T
    }    
}
downViewport("vp_map")
    pushViewport(plotViewport(margins=c(2,2,2,2)))
    pushViewport(dataViewport(c(-180,180),c(-90,90)))
    grid.xaxis(at=c(-180,-120,-90,-60,-30,0,30,60,90,120,180),main=T)
    grid.xaxis(at=c(-180,-120,-90,-60,-30,0,30,60,90,120,180),main=F)
    grid.text('Longitude',y=unit(-3,"lines"))
    grid.yaxis(at=c(-90,-60,-30,0,30,60,90),main=T)
    grid.yaxis(at=c(-90,-30,0,30,60,90),main=F)
    grid.text('Latitude',x=unit(-3.5,"lines"), rot=90)
    grid.lines(x=unit(sr.map.internal.wm$x,"native"),
               y=unit(sr.map.internal.wm$y,"native"),gp=gp_grey)
    grid.points(x=unit(sts$V14,"native"),y=unit(sts$V13,'native'),pch=20,
               size=unit(3,"native"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()

# Plot the AIR temperatures
downViewport("vp_at")
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(sts$Date),c(sts$V8,
               quantile(sts$V7,probs=c(0.02,0.98),na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V8,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()

# Plot the SSTs or WS - whichever there are more of
downViewport("vp_sst")
pushViewport(plotViewport(margins=c(2,2,2,2)))
if(length(na.omit(sts$V5)) > length(na.omit(sts$V11))) { # SST
pushViewport(dataViewport(as.numeric(sts$Date),c(sts$V6,
               quantile(sts$V5,probs=c(0.02,0.98),na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Sea Temperature (C)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V6,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V5,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=gp_red)
popViewport()
} else { # WS
pushViewport(dataViewport(as.numeric(sts$Date),c(sts$V12,
               quantile(sts$V11,probs=c(0.02,0.98),na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Wind Speed (m/s)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V12,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V11,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=gp_red)
popViewport()
}  
popViewport() 
upViewport()

# Plot the SLPs
downViewport("vp_slp")
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(sts$Date),c(sts$V10,
               quantile(sts$V9,probs=c(0.02,0.98),na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Pressure (hPa)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V10,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V9,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()



