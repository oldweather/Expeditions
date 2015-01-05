# R script to plot AT time-series for the Scotia
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
tics = pretty(sts$Date)
ticl = dates(tics)
      
pdf(file="../figures/SLP.pdf",height=6,width=10,family="Helvetica",pointsize=12)
                    
# Make the plot environment
pushViewport(viewport(width=0.95,height=0.95,x=0.05,y=0.05,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(955,1030)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-2.5,"lines"))
grid.yaxis(main=T)
grid.text('Pressure (hPa)',x=unit(-3.5,"lines"), rot=90)

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V10,'native'),gp=sgb)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V9,'native'),pch=20,
               size=unit(1,"native"),gp=sgp)
popViewport()
popViewport()
popViewport()
