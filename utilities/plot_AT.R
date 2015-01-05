# R script to plot AT time-series
library(grid)
library(chron)
library(auto.tics)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = pretty(sts$Date) 

pdf(file="../figures/AT.pdf",width=11.7,height=8.3,family="Helvetica",pointsize=16)
#png(file="AT.png",width=400,height=300,pointsize=10)
                    
# Estimate a point size for the plot
pointSize <- min(4.0/length(sts$Date),0.05)

# Make the plot environment
pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.00,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(4,5,1,1)))
pushViewport(dataViewport(as.numeric(sts$Date),c(sts$V7,sts$V8)))
grid.xaxis(at=as.numeric(tics),label=attr(tics,'label'),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=sgp)
   sgn = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwx=2)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V8,'native'),gp=sgn)
