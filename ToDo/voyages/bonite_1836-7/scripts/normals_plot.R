# Plot Pressure, AT, SST and ice - obs and reanalysis - along
# the voyage

library(grid)
library(chron)

o<-read.table('Bonite.normal.comparisons')
dates<-chron(dates=sprintf("%04d/%02d/%02d",o$V1,o$V2,o$V3),
             times=sprintf("%02d:00:00",o$V4),
             format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(dates)
ticl=attr(tics,'labels')
                     

pdf(file="Bonite_comparison.pdf",
    width=10,height=10*sqrt(2),family='Helvetica',
    paper='special',pointsize=12)

# Pressure along the bottom with x axis
pushViewport(viewport(width=1.0,height=0.38,x=0.0,y=0.0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(dates,c(960,1040)))
      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Sea-level pressure (hPa)',x=unit(-4,'lines'),rot=90)
         

         # 20CR Normal+sd
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
pushViewport(viewport(width=1.0,height=0.31,x=0.0,y=0.38,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-10,30)))

         grid.yaxis(main=T)
         grid.text('Air temperature (C)',x=unit(-4,'lines'),rot=90)
         
         # 20CR Normal+sd
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
pushViewport(viewport(width=1.0,height=0.31,x=0.0,y=0.38+0.31,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-3,35)))

         grid.yaxis(main=T)
         grid.text('SST (C)',x=unit(-4,'lines'),rot=90)
         

         # 20CR Normal+sd
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

