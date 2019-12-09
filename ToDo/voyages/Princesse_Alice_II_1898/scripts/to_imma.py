#!/opt/local/bin/python
"""
 Version 1.11  Changed IMMA print statement to fix the fixed length Ship Identifier to 9 characters
 Version 1.1 added special code to notify about the international dateline crossing this requires one to
 edit by hand the output IMMA to fix the lat/lon and possibly the date between the areas flaged with the word
 fix

 This is an example program to process digitised logbook data from Jamestown (1886) into IMMA records.

 Specifically for the Jamestown_1886 transcribed logbook:
 There are two input files used, one for the position of the ship and the other for the observations

 The format of the positions file is 7 columns of tab separated fields 

 DD/MM/YYYY         Log lat        Log Long            Estimated Lat   Estimated Lon                Corrected Lat                Corrected Long
 12/03/1886         15 22 N         61 42 W              NA              NA                             NA                              NA

     * columns 2 and 3 the lat/lon are in degrees and minutes with additional character indicating North/South East/West
     * otherwise in degrees North and degrees East
     * all positions are assumed to be at 12noon local time
     * assumes no significant gaps in time for the positions

 The format of the observations file is 6 columns of tab separated fields

 DD/MM/YYYY      HR   air_temp  sfc_temp baro_temp Pressure Hg
 13/03/1886       3      78      78        81       30.03

     * All temperatures are in degrees Fahrenheit
     * Pressure are in inches Hg
  	
  We have assumed that the ships logs have already adjusted their local time when crossing the international dateline.
"""

# lmrlib (long marine report library) contains well documented and thoroughly validated subroutines and functions for historical units conversions
import lmrlib
# SciPy library for interpolation
import scipy.interpolate

import datetime 
# the identifing ship name that will be written into the IMMA record
Name='Albatross_1890';
Name= Name[0:9]

#Get the observations
obsFilename = file("obs.qc.out.revised")
#DD/MM/YYYY       H   air_temp  sfc_temp baro_temp Pressure Hg
#13/03/1886       3      78      78      81      30.03

# Get the positions
posFilename = file("positions.qc.out.revised")
#DD/MM/YYYY         Log lat        Log Long            Estimated Lat   Estimated Lon                Corrected Lat                Corrected Long
#12/03/1886         15 22 N         61 42 W              NA              NA                             NA                              NA

#https://stackoverflow.com/questions/29278265/python-comparing-columns-in-2-files-and-returning-merged-output
d = {}

#need a place holder for saving previous position for interpolation
first = 'yes'
delta_day = 0
add_char = ""
#read in the entire positions file, interpolating to every hour
while True:
  line = posFilename.readline()
  if not line:
    break
  #print line.split("\t")
  #pc0 date 12pm local time
  #pc1 ship lat
  #pc2 ship lon
  #pc3 estimate lat
  #pc4 estimate lon
  #pc5 corrected lat
  #pc6 corrected lon
  pc0,pc1,pc2,pc3,pc4,pc5,pc6,pc7 = line.split("\t")
  #print "got a new line ",pc0.strip()
  #if using the first two columns they are in degrees minutes
  #print pc0.strip()
  skip = "true"
  if pc1.strip() != "NA" and pc2.strip() != "NA":
     skip = "false"
     pc1deg,pc1min,pc1dir = pc1.strip().split(" ")
     plat = float(pc1deg) + float(pc1min)/60.
     pc2deg,pc2min,pc2dir = pc2.strip().split(" ")
     plon = float(pc2deg) + float(pc2min)/60.

     #adjust to degrees North and degrees East
     if "S" in pc1dir:
       plat *= -1
     if "s" in pc1dir:
       plat *= -1
     if "W" in pc2dir:
       plon = 360 - plon 
     if "w" in pc2dir:
       plon =  360 - plon 

  # otherwise use the best guess for location of the ship (already in degrees North and degrees East) 
  elif pc3.strip() != "NA" and pc4.strip() != "NA":
     skip = "false"
     plat = float(pc3.strip())
     plon = float(pc4.strip())

  # need to have positive longitude
  if (skip == "false"):
     if plon < 0:
        plon += 360  
   
     # can't interpolate yet need the first location of the ship
     if (first == 'yes'):
        ptime0 = pc0.strip()
        plat0 = plat
        plon0 = plon
        plon0_for_obs = plon0
        first = 'no'
     else:
        #interpolate the positions from 12 noon to 12 noon the next day (hour 36)
        #fill the gaps in location
        hour = 12

        while hour <= 35:
          plat_interp = scipy.interpolate.interp1d([12,36],[plat0,plat])
          plon_interp = scipy.interpolate.interp1d([12,36],[plon0,plon])

          if (hour <= 24):

            d[(ptime0+'/'+str(hour)+add_char)] = (ptime0)+'/'+str(hour),round(plat_interp(hour),2),round(plon_interp(hour),2)
#            print ptime0+'/'+str(hour)+add_char,round(plat_interp(hour),2),round(plon_interp(hour),2)

          else:
  #add a day to time stamp
            date_1 = datetime.datetime.strptime(ptime0, "%d/%m/%Y")
            #print "hour gt 24 ",ptime0,date_1.day
            jday = lmrlib.time_date2julianday(int(date_1.day),int(date_1.month),int(date_1.year))
            jday += 1
             # find the calendar date using the UTC julian day
            iday,imonth,iyear = lmrlib.time_julianday2date(jday)
              #print "increase day ",date_1.day,iday

            d[(str(iday)+'/'+str(imonth)+'/'+str(iyear)+'/'+str(hour - 24)+add_char)] = str(iday)+'/'+str(imonth)+'/'+str(iyear)+'/'+str(hour - 24),round(plat_interp(hour),2),round(plon_interp(hour),2)
#            print str(iday)+'/'+str(imonth)+'/'+str(iyear)+'/'+str(hour - 24)+add_char,round(plat_interp(hour),2),round(plon_interp(hour),2) 

          hour += 1 

 
        if (ptime0 == pc0.strip()):
          if (plon < 180):
             add_char = ""
          else:
             add_char = "N"
#          print "dateline crossing adding N", ptime0,pc0.strip()
#          print plon,delta_day,add_char
        else:
          add_char = ""
   
     ptime0 = pc0.strip()
     plat0 = plat
     plon0 = plon
   
#match the observations with the newly created hourly positions
last_time0 = "01/01/1600"

while True:
  line = obsFilename.readline()
  if not line:
    break
  #print line.split("\t")
  #observations tab separated columns 0-6
  #obc0 date
  #obc1 hour
  #obc2 air temp
  #obc3 surface temp
  #obc4 barometer temp
  #obc5 pressure
  obc0,obc1,obc2,obc3,obc4,obc5,obc6 = line.split("\t")

  if obc5.strip() != 'NA':

     #print "obs_time",obc0.strip()," <= last_time ",last_time0
     if (obc1.strip() == "12"):
        if (obc0.strip() == last_time0):
           add_char = "N"
           #print "fix lat/lon around crossing",obc0.strip(), last_time0
        else:
           add_char = ""

     slp = float(obc5.strip())
     day,month,year = obc0.strip().split("/")
     hour = int(obc1.strip())
  else:
     slp = 9999.9

 #do the times match? 
#     print obc0.strip()+'/'+str(hour)+add_char
  if (obc0.strip()+'/'+str(hour)+add_char) in d:
    vals = d[(obc0.strip()+'/'+str(hour)+add_char)]

    #if there is an air temperature convert to celcius
    air_temp = 999.9 
    if obc2.strip() != 'NA':
       air_temp = int(obc2.strip())
       air_temp = lmrlib.temp_f2c(air_temp)

    #if there is an sea surface temperature convert to celcius
    SS_temp = 999.9 
    if obc3.strip() != 'NA':
       SS_temp = int(obc3.strip())
       SS_temp = lmrlib.temp_f2c(SS_temp)

    if (slp != 9999.9):
       # Unit convertion hundredth inches of Hg to inches of Hg
       if slp > 2500.:
          slp /= 100.

       # If Barometer Temperature Doing Temperature correction 
       if obc4.strip() != 'NA':
          bar_temp = int(obc4.strip())
          # correction value for barometer temperature input in Fahrenheit
          slp += lmrlib.baro_tempF_correction(slp,bar_temp)

       # convert inches of Hg to mbars
       slp = lmrlib.baro_Eng_in2mb(slp)

       # Add gravity-correct the pressures
       slp += lmrlib.baro_G_correction(slp,vals[1],2)

    # Now we've got positions - convert the dates to UTC
    # need East Longitude
    if vals[2] < 0:
       elon = vals[2] + 360
       #print elon
    else:
       elon = vals[2]
       #print elon
    #plon0_for_obs
    if (plon0_for_obs < 180. and elon > 180.):
       print "fix day and lat/lon above upto hour 12"

    if (plon0_for_obs > 180. and elon < 180.):
       print "fix day below"

    # easy way to "fudge" having an hour 24 rather then add a day and hour 00
    # hour local standard
    if hour == 24:
       hour100 = 2399
    else:
       hour100 = int(hour)*100 

    # standard hour must be in hundredths
    elon100 = int(elon*100)

    # convert day month year to JulianDay
    jday = lmrlib.time_date2julianday(int(day),int(month),int(year))

    # using standard hour (hour100) and Julian day (jday) convert to coordinated universal time
    uhour,uday = lmrlib.time_local_hour_julianday2UTC(int(hour100),jday,int(elon100))

    # find the calendar date using the UTC julian day 
    iday,imonth,iyear = lmrlib.time_julianday2date(uday)

    # output in formatted column specific IMMA format

    #print obc0.strip()+'/'+str(hour)+add_char,int(round(vals[1],2)*100),int(round(vals[2],2)*100)
    #print without fixes to easier to match up
    #print("%4s%2s%2s%4s%5d%6d%20s%21s%9s%16s" % (iyear,imonth,iday,str(int(uhour)).zfill(4),int(round(vals[1],2)*100), \
    #       int(round(vals[2],2)*100),Name,obc5.strip(),obc2.strip(),obc3.strip()))

    #only print if one variable isn't missing
    if (slp != 9999.9 or air_temp != 999.9 or SS_temp != 999.9):
       print("%4s%2s%2s%4s%5d%6d%11s%9s%16s%5d%5s%4d%12s%4d" % (iyear,imonth,iday,str(int(uhour)).zfill(4),int(round(vals[1],2)*100), \
           int(round(vals[2],2)*100)," ",Name," ",int(10*round(slp,1))," ",int(round(air_temp*10,0))," ",int(round(SS_temp*10))))
    plon0_for_obs = elon
  
  if (hour == 13):
    last_time0 = obc0.strip()
