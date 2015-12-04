# Plot Pressure obs and reanalysis - along part of the voyage

library(grid)
library(chron)

o<-read.table('../Endurance.comparisons')
o2<-read.table('../Endurance.comparisons.ERA20C')
o3<-read.table('../Endurance.comparisons.354')
dates<-chron(dates=sprintf("%04d/%02d/%02d",o$V1,o$V2,o$V3),
             times=sprintf("%02d:00:00",o$V4),
             format=c(dates = "y/m/d", times = "h:m:s"))

# Pic a time range to display
p.x<-chron(dates=c("1914/08/08","1915/08/08"),times="12:00:00",
                    format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(p.x,min.n=7)
ticl=attr(tics,'labels')

w<-which(dates>=p.x[1]&dates<p.x[2])
                    
pdf(file="Endurance_pressure.pdf",
    width=15,height=7,family='Helvetica',
    paper='special',pointsize=18)

# Pressure along the bottom with x axis
pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(p.x,c(960,1040)))
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date (1914-15)',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Sea-level pressure (hPa)',x=unit(-4,'lines'),rot=90)
         
         # 20CR Analysis spreads
         gp=gpar(col=rgb(0.8,0.8,1,1),fill=rgb(0.8,0.8,1,1))
         for(i in w) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o$V6[i]-(o$V7[i])*2,
                 o$V6[i]-(o$V7[i])*2,
                 o$V6[i]+(o$V7[i])*2,
                 o$V6[i]+(o$V7[i])*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         gp=gpar(col=rgb(0.4,0.4,1,1),fill=rgb(0.4,0.4,1,1))
         for(i in w) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o3$V6[i]-(o3$V7[i])*2,
                 o3$V6[i]-(o3$V7[i])*2,
                 o3$V6[i]+(o3$V7[i])*2,
                 o3$V6[i]+(o3$V7[i])*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
            
        # Observation
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(dates[w],'native'),
                     y=unit(o$V5[w],'native'),
                     size=unit(0.005,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
   popViewport()
popViewport()
     

