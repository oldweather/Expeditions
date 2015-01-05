# R script to plot temperature and pressure time-series for the First Fleet
library(grid)
library(chron)

# Read in the data
# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),
                           format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1787/05/01','1787/07/01','1787/09/01','1787/11/01','1788/01/01','1788/03/01'),
      format="y/m/d")
ticl = c('1787/05','1787/07','1787/09','1787/11','1788/01','1788/03')
      
pdf(file="../figures/All.pdf",width=8.3,height=11.7,
    family="Helvetica",pointsize=16)
                    
gp_red   = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
gp_black = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lex=1.5)
sgp      = gpar(col=rgb(0.9,0.9,0.9,1),fill=rgb(0.9,0.9,0.9,1))

# Add the annotations
gp_ant = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),fontfamily="Helvetica",fontsize=10)
pushViewport(viewport(width=1.0,height=1.0,x=0.00,y=0.00,
                      just=c("left","bottom"),name="vp_map"))
pushViewport(plotViewport(margins=c(1,4,0,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(0,1)))

 # Tenerife
   grid.polygon(x=unit(c(as.numeric(dates(c('1787/06/05','1787/06/05',
                     '1787/06/09','1787/06/09'),format="y/m/d"))),"native"),
                y=unit(c(0.06,0.98,0.98,0.06),"native"),gp=sgp)
   grid.text("Tenerife",
             x=unit(c(as.numeric(dates('1787/06/07',format="y/m/d"))),"native"),
             y=unit(1.0,"native"),gp=gp_ant)
 # Equator
   grid.polygon(x=unit(c(as.numeric(dates(c('1787/07/13','1787/07/13',
                     '1787/07/14','1787/07/14'),format="y/m/d"))),"native"),
                y=unit(c(0.06,0.98,0.98,0.06),"native"),gp=sgp)
   grid.text("Equator",
             x=unit(c(as.numeric(dates('1787/07/13',format="y/m/d"))),"native"),
             y=unit(1.0,"native"),gp=gp_ant)

 # In Rio Harbour
   grid.polygon(x=unit(c(as.numeric(dates(c('1787/08/06','1787/08/06',
                     '1787/09/04','1787/09/04'),format="y/m/d"))),"native"),
                y=unit(c(0.06,0.98,0.98,0.06),"native"),gp=sgp)
   grid.text("Rio de\nJaneiro",
             x=unit(c(as.numeric(dates('1787/08/19',format="y/m/d"))),"native"),
             y=unit(1.0,"native"),gp=gp_ant)

 # In Cape Town Harbour
   grid.polygon(x=unit(c(as.numeric(dates(c('1787/10/14','1787/10/14',
                     '1787/11/13','1787/11/13'),format="y/m/d"))),"native"),
                y=unit(c(0.06,0.98,0.98,0.06),"native"),gp=sgp)
   grid.text("Cape\nTown",
             x=unit(c(as.numeric(dates('1787/10/30',format="y/m/d"))),"native"),
             y=unit(1.0,"native"),gp=gp_ant)

 # New Year storms
   grid.polygon(x=unit(c(as.numeric(dates(c('1788/01/01','1788/01/01',
                     '1788/01/02','1788/01/02'),format="y/m/d"))),"native"),
                y=unit(c(0.06,0.98,0.98,0.06),"native"),gp=sgp)
   grid.text("New year's\nday storms",
             x=unit(c(as.numeric(dates('1788/01/02',format="y/m/d"))),"native"),
             y=unit(1.0,"native"),gp=gp_ant)

popViewport() 
popViewport() 
popViewport() 

              
# AT
pushViewport(viewport(width=1.0,height=0.45,x=0.00,y=0.0,
                      just=c("left","bottom"),name="at"))
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
popViewport() 

# PRE
pushViewport(viewport(width=1.0,height=0.45,x=0.0,y=0.45,
                      just=c("left","bottom"),name="slp"))
pushViewport(plotViewport(margins=c(1,4,0,2)))
pushViewport(dataViewport(as.numeric(c(sts$Date[1],sts$Date[length(sts$Date)])),c(990,1030)))
grid.yaxis(main=T)
grid.text('Pressure (hPa)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V10,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V9,'native'),pch=20,
               size=unit(4,"native"),gp=gp_blue)
popViewport() 
popViewport() 
popViewport() 


               
