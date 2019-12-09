#!/usr/bin/env python

# Process digitised logbook data from the Princesse Alice II into
#  IMMA records.

import sys
import os
import csv
import IMMA
from lmrlib import (baro_mm2mb,
                    time_local_hour_julianday2UTC,
                    time_date2julianday,
                    time_julianday2date)

Ship_name = 'PcsAlice2'
Lat_flag = 'N';
Lon_flag = 'W';
Last_lon = -2.99;
Last_lat = 53.40;

opfile='../../../imma/Princesse_Alice_1898.imma'
opfile='./raw.imma'
opw=open(opfile,'wb')

with open('%s/../as_digitised/ALBERT_1_1898a.csv' % 
                  os.path.abspath(os.path.dirname(__file__)), 'r') as csvr:
    rdr = csv.reader(csvr, delimiter=',')
    count=0

    for Fields in rdr:
        count += 1
        if count <= 3: continue  # Headers
        Ob = {}
        Ob['attachments'] = []
        Ob['attachments'].append(0)
        Ob['ATTC']=0
        for p in IMMA.parameters[0]: Ob[p]=None

        if len(Fields[0])>0 and not Fields[0].isspace():
            Year = Fields[0]
        if len(Fields[1])>0 and not Fields[1].isspace():
            Month = Fields[1]
        if len(Fields[2])>0 and not Fields[2].isspace():
            Day = Fields[2]
        if len(Fields[3])>0 and not Fields[3].isspace():
            Hour = Fields[3]

        Ob['YR'] = int(Year)
        Ob['MO'] = int(Month)
        Ob['DY'] = int(Day)
        Ob['HR'] = int(Hour)//100+(int(Hour)%100)/60
        if Ob['HR'] == 24: Ob['HR']=23.99

        if len(Fields[13])>0 and not Fields[13].isspace():
            Ob['LAT'] = float(Fields[13])
            Last_lat = Ob['LAT']
        if len(Fields[14])>0 and not Fields[14].isspace():
            Ob['LON'] = float(Fields[14])
            Last_lon = Ob['LON']

        # Convert ob date and time to UTC
        # Start by assuming at UTC
        if ( Last_lon is not None
             and Ob['HR'] is not None
             and Ob['DY'] is not None
             and Ob['MO'] is not None
             and Ob['YR'] is not None ):
            elon = 0;   # Last_lon
            if elon < 0:   elon += 360
            ( uhr, udy ) = time_local_hour_julianday2UTC(
                Ob['HR'] * 100,
                time_date2julianday( Ob['DY'], Ob['MO'], Ob['YR'] ),
                elon * 100)
            Ob['HR'] = uhr / 100
            ( Ob['DY'], Ob['MO'], Ob['YR'] ) = time_julianday2date(udy);
        else: 
            Ob['HR'] = None

        if len(Fields[8])>0 and not Fields[8].isspace():
            Ob['SLP'] = baro_mm2mb(float(Fields[8]))
        # Barometer is an aneroid -> no corrections

        # Fill in extra metadata
        Ob['IM']   = 0         # C
        Ob['ATTC'] = 0         # No attachments - may have supplemental, see below
        Ob['TI']   = 0         # Nearest hour time precision
        Ob['DS']   = None      # Unknown course
        Ob['VS']   = None      # Unknown speed
        Ob['NID']  = 3         #
        Ob['II']   = 10        #
        Ob['ID']   = Ship_name
        Ob['C1']   = '04'      #

        # Add the original record as a supplemental attachment
        Ob['attachments'].append(99)
        Ob['ATTC'] +=1
        Ob['ATTE'] = None;
        Ob['SUPD'] = ' '.join(Fields)

        IMMA.write(Ob, opw)


