# Show winds along the route of the James Caird

library(chron)
library(grid)

load('JC.wind.modern.Rdata')
beaufort<-JC.wind.modern
f.bound<-c(0,0.3,1.5,3.3,5.5,8,10.8,13.9,17.2,20.7,24.5,28.4,32.6,1000)
for(f in seq(1,12)) {
   w<-which(JC.wind.modern>=f.bound[f] & JC.wind.modern<f.bound[f+1])
   beaufort[w]<-f
}

obs<-data.frame(
c(1916,4,24,12,6),
c(1916,4,24,16,6),
c(1916,4,25,6,5),
c(1916,4,25,12,6),
c(1916,4,26,12,8),
c(1916,4,27,12,8),
c(1916,4,30,12,8),
c(1916,5,1,12,7),
c(1916,5,4,12,4),
c(1916,5,5,12,5),
c(1916,5,5,20,3),
c(1916,5,6,12,7),
c(1916,5,8,15,6),
c(1916,5,8,15,8),
c(1916,5,9,12,8),
c(1916,5,12,12,6))
obs.chron<-chron(dates=sprintf("%04d-%02d-%02d",as.integer(obs[1,]),as.integer(obs[2,]),as.integer(obs[3,])),
                 times=sprintf("%02d:00:00",as.integer(obs[4,])),
                 format=c(dates = "y-m-d", times = "h:m:s"))
obs.chron<-obs.chron-0.1 # Approx UTC adjustment

worst<-rep(NA,30)
for(i in seq(1,30)) worst[i]<-max(beaufort[i,])
print(worst[order(worst)])


pdf(file="James_Caird_wind.pdf",
    width=10*sqrt(2),height=10,family='Helvetica',
    paper='special',pointsize=18,bg='white')

# Enter the ice
id<-chron(dates=c("1916/04/23","1916/05/14"),
          times=c("00:00:00","23:59:59"),
          format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(id,n=7)
ticl=attr(tics,'labels')
pushViewport(viewport(width=1.0,height=1.0,x=0,y=0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(id,c(0,12)))
         grid.xaxis(main=T,at=tics,label=ticl)
         grid.text('Date (1916)',y=unit(-3,'lines'))
         grid.yaxis(main=T,at=seq(0,12))
         grid.text('Wind Force (Beaufort)',x=unit(-3,'lines'),rot=90)
         gp=gpar(col=rgb(0.75,0.75,1,1),fill=rgb(0.75,0.75,1,1),lty=1,lwd=0.5)
         for(i in seq(1,30)) {
	     grid.points(x=unit(jitter(o$chron,amount=0.5),'native'),
			 y=unit(jitter(beaufort[i,],amount=0.5),'native'),
                         size=unit(0.005,'npc'),
                         pch=21,
			 gp=gp)
         }
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lty=1)
	     grid.points(x=unit(obs.chron,'native'),
			 y=unit(obs[5,],'native'),
                         size=unit(0.01,'npc'),
                         pch=21,
			 gp=gp)
 
      popViewport()
   popViewport()
popViewport()

dev.off()
