# Make a route map for the first fleet.
library(grid)
library(chron)
library(lattice)
library(maps)

# Load the map functions
#source("sr.map.R")
gp_red   = gpar(col=rgb(1,0,0,1),fill=rgb(1,0,0,1))
gp_blue  = gpar(col=rgb(0,0,1,1),fill=rgb(0,0,1,1))
gp_black = gpar(col=rgb(0,0,0,1),fill=rgb(0,0,0,1),lex=1.5)
gp_grey  = gpar(col=rgb(0.3,0.3,0.3,1),fill=rgb(0.3,0.3,0.3,1),lex=1.2)

# Read in the data
sts<-read.table('ovn.out',header=F)
postscript(file="../figures/Sirius_route.eps",paper="a4",family="Helvetica",pointsize=12)
                    
# Draw the map
sr.map.internal.wm <- map('world',interior=FALSE,plot=FALSE)
is.na(sr.map.internal.wm$x[8836])=T  # Remove Antarctic bug

pushViewport(viewport(width=1.0,height=1.0,x=0.0,y=0.00,clip="on",
                      just=c("left","bottom"),name="vp_map"))
    pushViewport(plotViewport(margins=c(0,0,0,0)))
    pushViewport(dataViewport(c(-90,160),c(-60,65)))
    grid.lines(x=unit(sr.map.internal.wm$x,"native"),
               y=unit(sr.map.internal.wm$y,"native"),gp=gp_grey)
    grid.points(x=unit(sts$V14,"native"),y=unit(sts$V13,'native'),pch=20,
               size=unit(3,"native"),gp=gp_red)
popViewport() 
popViewport() 
upViewport()

