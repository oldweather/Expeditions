# R script to plot AT and Ice-cover time-series for Scoresby 1810-18
library(grid)
library(chron)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts2<-read.table('ice_range_1979-2004.out',header=F)
sts2$Date<-chron(dates=as.character(sts2$V1),times=as.character(sts2$V2),format=c(dates = "y/m/d", times = "h:m:s"))
sts4<-read.table('at_range_1979-2004.out',header=F)
sts4$Date<-chron(dates=as.character(sts4$V1),times=as.character(sts4$V2),format=c(dates = "y/m/d", times = "h:m:s"))
      
postscript(file="../figures/AT+I.ps",paper="a4",horizontal=F,family="Helvetica",pointsize=10)
                    
years = c(1810,1811,1812,1813,1814,1815,1816,1817,1818,1822)
x=c(0,0.5,0,0.5,0,0.5,0,0.5,0,0.5)
y=c(0.8,0.8,0.6,0.6,0.4,0.4,0.2,0.2,0,0)

for(i in seq(1,10)) {
 tics =  dates(c(sprintf("%s/4/1",years[i]),sprintf("%s/5/1",years[i]),
          sprintf("%s/6/1",years[i]),sprintf("%s/7/1",years[i])),format="y/m/d")
 ticl = c('Apr 1','May 1','Jun 1','Jul 1')
 drange = dates(c(sprintf("%s/03/26",years[i]),sprintf("%s/07/31",years[i])),format="y/m/d")
 
 if(i==10) {
   tics=dates(c("1822/05/01","1822/06/01","1822/07/01","1822/08/01","1822/09/01"),format="y/m/d")
 ticl = c('May 1','Jun 1','Jul 1','Aug 1','Sep 1')
 drange = dates(c(sprintf("%s/04/11",years[i]),sprintf("%s/09/18",years[i])),format="y/m/d")
 }
 
pushViewport(viewport(width=0.5,height=0.2,x=x[i],y=y[i],
                      just=c("left","bottom"),clip='on'))
pushViewport(viewport(width=0.95,height=0.25,x=0.05,y=0.05,
                      just=c("left","bottom"),name="ice"))
pushViewport(plotViewport(margins=c(2,3,0,3)))
pushViewport(dataViewport(as.numeric(drange),c(0,1)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.yaxis(main=F,at=c(0,1))
if(i==1) grid.text('Sea-ice',x=unit(1.15,"npc"), rot=90)
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts2$Date,"native"),y=unit(sts2$V5,'native'),gp=sgb)
popViewport() 
popViewport() 
popViewport() 
              
pushViewport(viewport(width=0.95,height=0.75,x=0.05,y=0.25,
                      just=c("left","bottom"),name="at"))
pushViewport(plotViewport(margins=c(0,3,2,3)))
pushViewport(dataViewport(as.numeric(drange),c(-20,10)))
grid.yaxis(main=T)
if(i==1) grid.text('Air Temperature (C)',x=unit(-3,"lines"), rot=90)
grid.text(sprintf("%04d",years[i]),x=unit(0.8,"npc"),y=unit(0.2,"npc"))

   sgp = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
   sgn = gpar(col=rgb(0.7,0.7,0.7,1),fill=rgb(0,0,0,1),lwd=2)
   sgb = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lwd=2)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V3,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V4,'native'),gp=sgn)
   grid.lines(x=unit(sts4$Date,"native"),y=unit(sts4$V5,'native'),gp=sgb)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V7,'native'),pch=20,
               size=unit(3,"native"),gp=sgp)
popViewport() 
popViewport() 
popViewport()
popViewport()

}
