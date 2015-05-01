# Plot Pressure, AT, SST and ice - obs and reanalysis - along
# the voyage

library(grid)
library(chron)

o<-read.table('James_Caird.comparisons')
o<-rbind(o,read.table('Emma+Yelcho.comparisons'))
o2<-read.table('James_Caird.comparisons.ERA20C')
o2<-rbind(o2,read.table('Emma+Yelcho.comparisons.ERA20C'))
o3<-read.table('James_Caird.comparisons.354')
o3<-rbind(o3,read.table('Emma+Yelcho.comparisons.354'))
dates<-chron(dates=sprintf("%04d/%02d/%02d",o$V1,o$V2,o$V3),
             times=sprintf("%02d:00:00",o$V4),
             format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(dates)
ticl=attr(tics,'labels')

pdf(file="James_Caird+Emma+Yelcho_comparison.pdf",
    width=10,height=10*sqrt(2),family='Helvetica',
    paper='special',pointsize=12)

# Pressure along the bottom with x axis
pushViewport(viewport(width=1.0,height=0.34,x=0.0,y=0.0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(dates,c(960,1040)))
      
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Sea-level pressure (hPa)',x=unit(-4,'lines'),rot=90)
         

         # 20CR Analysis spreads
         gp=gpar(col=rgb(0.8,0.8,1,1),fill=rgb(0.8,0.8,1,1))
         for(i in seq_along(o$V1)) {
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
         for(i in seq_along(o3$V1)) {
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
     # ERA20C best-estimate
         gp=gpar(col=rgb(1,0.4,0.4,1),fill=rgb(1,0.4,0.4,1))
         grid.lines(x=unit(dates,'native'),
                    y=unit(o2$V6,'native'),
                      gp=gp)

            
        # Observation
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(dates,'native'),
                     y=unit(o$V5,'native'),
                     size=unit(0.005,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
   popViewport()
popViewport()
     
# AT next up
pushViewport(viewport(width=1.0,height=0.28,x=0.0,y=0.34,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-30,30)))

         grid.yaxis(main=T)
         grid.text('Air temperature (C)',x=unit(-4,'lines'),rot=90)
         

         # 20CR Analysis spreads
         gp=gpar(col=rgb(0.8,0.8,1,1),fill=rgb(0.8,0.8,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o$V9[i]-(o$V10[i])*2,
                 o$V9[i]-(o$V10[i])*2,
                 o$V9[i]+(o$V10[i])*2,
                 o$V9[i]+(o$V10[i])*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         gp=gpar(col=rgb(0.4,0.4,1,1),fill=rgb(0.4,0.4,1,1))
         for(i in seq_along(o3$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o3$V9[i]-(o3$V10[i])*2,
                 o3$V9[i]-(o3$V10[i])*2,
                 o3$V9[i]+(o3$V10[i])*2,
                 o3$V9[i]+(o3$V10[i])*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
     # ERA20C best-estimate
         gp=gpar(col=rgb(1,0.4,0.4,1),fill=rgb(1,0.4,0.4,1))
         grid.lines(x=unit(dates,'native'),
                    y=unit(o2$V9,'native'),
                      gp=gp)
            
        # Observation
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(dates,'native'),
                     y=unit(o$V8,'native'),
                     size=unit(0.005,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
   popViewport()
popViewport()

# SST next up
pushViewport(viewport(width=1.0,height=0.28,x=0.0,y=0.34+0.28,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-3,35)))

         grid.yaxis(main=T)
         grid.text('SST (C)',x=unit(-4,'lines'),rot=90)
         

         # 20CR Analysis spreads
         gp=gpar(col=rgb(0.8,0.8,1,1),fill=rgb(0.8,0.8,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(o$V12[i]-(o$V13[i])*2,
                 o$V12[i]-(o$V13[i])*2,
                 o$V12[i]+(o$V13[i])*2,
                 o$V12[i]+(o$V13[i])*2)
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         # ERA20C best-estimate
         gp=gpar(col=rgb(1,0.4,0.4,1),fill=rgb(1,0.4,0.4,1))
         grid.lines(x=unit(dates,'native'),
                    y=unit(o2$V12,'native'),
                      gp=gp)
            
        # Observation
         gp=gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1))
         grid.points(x=unit(dates,'native'),
                     y=unit(o$V11,'native'),
                     size=unit(0.005,'npc'),
                     pch=20,
                     gp=gp)
      popViewport()
   popViewport()
popViewport()

# ice fraction
pushViewport(viewport(width=1.0,height=0.1,x=0.0,y=0.34+0.28+0.28,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,1,0)))
      pushViewport(dataViewport(dates,c(0,1)))

         grid.yaxis(main=T)
         grid.text('Ice fraction',x=unit(-4,'lines'),rot=90)
         
         # ERA20C value
         gp=gpar(col=rgb(1,0.4,0.4,1),fill=rgb(1,0.4,0.4,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(0,0,o2$V14[i],o2$V14[i])
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         # 20CR Analysis value
         gp=gpar(col=rgb(0.4,0.4,1,1),fill=rgb(0.4,0.4,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(0,0,o$V14[i],o$V14[i])
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
         # ERA20C overdraw
         gp=gpar(col=rgb(1,0.4,0.4,1),fill=rgb(1,0.4,0.4,1))
         grid.lines(x=unit(dates,'native'),
                    y=unit(o2$V14,'native'),
                      gp=gp)
            
      popViewport()
   popViewport()
popViewport()
