# Make an SST history figure for the Baquenado
library(grid)
library(chron)
library(lattice)
library(maps)

gp_red   = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_black = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lex=1.5)

# Read in the data
sts<-read.table('ovn.out',header=F)
sts$Date<-chron(dates=as.character(sts$V1),times=as.character(sts$V2),
                           format=c(dates = "y/m/d", times = "h:m:s"))
tics = dates(c('1918-03-01','1918-04-01','1918-05-01','1918-06-01','1918-07-01'),
      format="y-m-d")
ticl = c('1918/03','1918/04','1918/05','1918/06','1918/07')
      
#postscript(file="Baquenado_SST.eps",paper="a4",family="Helvetica",pointsize=12)
png(file="Baquenado_SST.png", width=400, height=300, pointsize=12)

                    upViewport(0)
pushViewport(viewport(width=0.9,height=0.9,x=0.1,y=0.15,
                      just=c("left","bottom"),name="vp_at"))
upViewport(0)


# Plot the AIR temperatures
downViewport("vp_at")
pushViewport(plotViewport(margins=c(2,2,2,2)))
pushViewport(dataViewport(as.numeric(c(tics[1],tics[5])),c(15,35)))
grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
grid.text('Date',y=unit(-3,"lines"))
grid.yaxis(main=T)
grid.text('Air Temperature (C)',x=unit(-3.5,"lines"), rot=90)
   grid.lines(x=unit(sts$Date,"native"),y=unit(sts$V6,'native'),gp=gp_black)
   grid.points(x=unit(sts$Date,"native"),y=unit(sts$V5,'native'),pch=20,
               size=unit(4,"native"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()



