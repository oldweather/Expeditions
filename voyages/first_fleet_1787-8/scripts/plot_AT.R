# Temperature time-series for the First Fleet
library(grid)
library(chron)

gp_red   = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_black = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lex=1.5)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),
                           format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1787/05/01','1787/07/01','1787/09/01','1787/11/01','1788/01/01','1788/03/01'),
      format="y/m/d")
ticl = c('1787/05','1787/07','1787/09','1787/11','1788/01','1788/03')
      
png(file="../kml/images/Sirius_AT.png", width=400, height=300, pointsize=12)

pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.0,
                      just=c("left","bottom"),name="vp_at"))
pushViewport(plotViewport(margins=c(4,4,0,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(10,30)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V16,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(4,"native"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()



