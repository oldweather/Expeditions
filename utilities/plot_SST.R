# R script to plot SST time-series for the expeditions
library(grid)
library(chron)
library(auto.tics)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = pretty(sts$Date) 
      
pdf(file="../figures/SST.pdf",width=11.7,height=8.3,family="Helvetica",pointsize=16)
                    
# Estimate a point size for the plot
pointSize <- min(4.0/length(sts$Date),0.05)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(min(sts$V5,na.rm=T),max(sts$V5,na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=attr(tics,'label'),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Sea Surface Temperature (C)',x=unit(-4,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V5,'native'),pch=20,
               size=unit(pointSize,"npc"),gp=sgp)
   sgn = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwx=2)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V6,'native'),gp=sgn)
