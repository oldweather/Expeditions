# Plot Pressure, AT, SST and ice - obs and reanalysis - along
# the voyage

library(grid)
library(chron)

o<-read.table('Endurance.comparisons')
dates<-chron(dates=sprintf("%04d/%02d/%02d",o$V1,o$V2,o$V3),
             times=sprintf("%02d:00:00",o$V4),
             format=c(dates = "y/m/d", times = "h:m:s"))
tics=pretty(dates)
ticl=attr(tics,'labels')
#tics=dates(c("1919/02/01","1919/04/01","1919/06/01","1919/08/01",
#           "1919/10/01","1919/12/01"),format="y/m/d")
#ticl=c("1919/02","1919/04","1919/06","1919/08",
#           "1919/10","1919/12")
                     

pdf(file="Endurance_comparison.pdf",
    width=10,height=10*sqrt(2),family='Helvetica',
    paper='special',pointsize=12)

# Pressure along the bottom with x axis
pushViewport(viewport(width=1.0,height=0.34,x=0.0,y=0.0,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(4,6,0,0)))
      pushViewport(dataViewport(dates,c(970,1040)))
      
      # Mark the major ports
         gp=gpar(col=rgb(0.98,0.98,0.98,1),fill=rgb(0.98,0.98,0.98,1))
         p.y<-c(975,975,1045+175,1045+175)
         p.x<-chron(dates=c("1914/10/08","1914/10/27",
                            "1914/10/27","1914/10/08"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
        # grid.polygon(x=unit(p.x,'native'),
        #              y=unit(p.y,'native'),
        #              gp=gp)
        # grid.text('Bermuda',
        #           x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
        #           y=unit(970,'native'),
        #           just=c('center','center'))
         p.y<-c(975,975,1045+175,1045+175)
         p.x<-chron(dates=c("1914/11/14","1914/12/05",
                            "1914/12/05","1914/11/14"),
                    times=rep("00:0:01",4),
                    format=c(dates = "y/m/d", times = "h:m:s"))
        # grid.polygon(x=unit(p.x,'native'),
        #              y=unit(p.y,'native'),
        #              gp=gp)
        # grid.text('Grytviken',
        #           x=unit((as.numeric(p.x[1])+as.numeric(p.x[2]))/2,'native'),
        #           y=unit(970,'native'),
        #           just=c('center','center'))

      
         grid.xaxis(at=as.numeric(tics),label=ticl,main=T)
         grid.text('Date',y=unit(-3,'lines'))
         grid.yaxis(main=T)
         grid.text('Sea-level pressure (hPa)',x=unit(-4,'lines'),rot=90)
         

         # Analysis spreads
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
pushViewport(viewport(width=1.0,height=0.28,x=0.0,y=0.34,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-10,40)))

         grid.yaxis(main=T)
         grid.text('Air temperature (C)',x=unit(-4,'lines'),rot=90)
         

         # Analysis spreads
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
pushViewport(viewport(width=1.0,height=0.28,x=0.0,y=0.34+0.28,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,0,0)))
      pushViewport(dataViewport(dates,c(-3,35)))

         grid.yaxis(main=T)
         grid.text('SST (C)',x=unit(-4,'lines'),rot=90)
         

         # Analysis spreads
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

# ice fraction
pushViewport(viewport(width=1.0,height=0.1,x=0.0,y=0.34+0.28+0.28,
                      just=c("left","bottom"),name="Page",clip='off'))
   pushViewport(plotViewport(margins=c(0,6,1,0)))
      pushViewport(dataViewport(dates,c(0,1)))

         grid.yaxis(main=T)
         grid.text('Ice fraction',x=unit(-4,'lines'),rot=90)
         
         # Analysis value
         gp=gpar(col=rgb(0.4,0.4,1,1),fill=rgb(0.4,0.4,1,1))
         for(i in seq_along(o$V1)) {
            x<-c(dates[i]-0.125,dates[i]+0.125,
                 dates[i]+0.125,dates[i]-0.125)
            y<-c(0,0,o$V14[i],o$V14[i])
            grid.polygon(x=unit(x,'native'),
                         y=unit(y,'native'),
                      gp=gp)
          }
            
      popViewport()
   popViewport()
popViewport()
