# Show ice coverage around Elephant Island

library(chron)
library(grid)

load('Elephant.comparisons.icec.Rdata')

pdf(file="Elephant_ice.pdf",
    width=10*sqrt(2),height=10,family='Helvetica',
    paper='special',pointsize=18,bg='white')

# Enter the ice
id<-chron(dates=c("1916/04/01","1916/11/01"),
          times=c("00:00:00","23:59:59"),
          format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(id)
ticl=attr(tics,'labels')
pushViewport(viewport(width=1.0,height=1.0,x=0,y=0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(id,c(0,1)))
         grid.xaxis(main=T,at=tics,label=ticl)
         grid.text('Date (1916)',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
         grid.text('Ice (Fraction)',x=unit(-3,'lines'),rot=90,gp=gp)
         gp=gpar(col=rgb(0.75,0.75,1,1),fill=rgb(0.75,0.75,1,1),lty=1,lwd=0.5)
         for(i in seq(1,30)) {
	     grid.lines(x=unit(o$chron,'native'),
			y=unit(elephant.icec.modern[i,],'native'),
			 gp=gp)
         }
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=1,lwd=2)
         grid.lines(x=unit(o$chron,'native'),
                    y=unit(elephant.icec.twcr,'native'),
                     gp=gp)
         gp=gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1),lty=2,lwd=2)
         grid.lines(x=unit(o$chron,'native'),
                    y=unit(elephant.icec.era,'native'),
                     gp=gp)
      popViewport()
   popViewport()
popViewport()

dev.off()
