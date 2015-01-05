# R script to plot AT time-series for the Resolution
library(grid)
library(chron)
library(auto.tics)

# Read in the data
sts<-read.table('../../../ovn/Resolution_C_1772-5.ovn',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2<-read.table('../../../ovn/Resolution_W1_1772-4.ovn',header=F)
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts3<-read.table('../../../ovn/Resolution_W2_1772-4.ovn',header=F)
sts3$Date<-chron(dates=as.character(sts3$V1),times=as.character(sts3$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = auto.time.tics(sts2$Date[1],sts$Date[length(sts$Date)]) 

pdf(file="../figures/AT.pdf",width=11.7,height=8.3,family="Helvetica",pointsize=16)
#png(file="AT.png",width=400,height=300,pointsize=10)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(sts2$Date[1],sts$Date[length(sts$Date)])),c(min(sts$V7,sts2$V7,sts3$V7,na.rm=T),max(sts$V7,sts2$V7,sts3$V7,na.rm=T))))
grid.xaxis(at=as.numeric(tics),label=as.character(tics),main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(5,"native"),gp=sgp)
   sgp = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
   grid.points(x=unit(sts2$Date,"native"),y=unit(sts2$V7,'native'),pch=20,
               size=unit(5,"native"),gp=sgp)
   sgp = gpar(col=rgb(0,1,0,1),fill=rgb(0,1,0,1))
   grid.points(x=unit(sts3$Date,"native"),y=unit(sts3$V7,'native'),pch=20,
               size=unit(5,"native"),gp=sgp)
   sgn = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwx=2)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V8,'native'),gp=sgn)
   sgn = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwx=2)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V8,'native'),gp=sgn)
