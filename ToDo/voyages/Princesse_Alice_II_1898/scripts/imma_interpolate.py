#!/usr/bin/env python

import scipy.interpolate
import IMMA
import datetime

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--input", help="Input file name",
                    type=str,required=True)
parser.add_argument("--output", help="Output file name",
                    type=str,required=True)
args = parser.parse_args()

def get_ob_date(ob):
    obdate=datetime.datetime(ob['YR'],
                                ob['MO'],
                                ob['DY'],
                                int(ob['HR']),
                                int((ob['HR']%1)*60))
    return obdate

obs=IMMA.read(args.input)
dates=[get_ob_date(ob) for ob in obs]
startdate=min(dates)
dates=[(get_ob_date(ob)-startdate).total_seconds() for ob in obs]

LATs=[ob['LAT'] for ob in obs if ob['LAT'] is not None]
LATd=[(get_ob_date(ob)-startdate).total_seconds() for ob in obs \
                                       if ob['LAT'] is not None]
LAT_if=scipy.interpolate.interp1d(LATd,LATs)
for i in range(len(obs)):
    if obs[i]['LAT'] is None:
        if dates[i]>max(LATd) or dates[i]<min(LATd):
            continue
        obs[i]['LAT'] = LAT_if(dates[i])
        obs[i]['LI'] = 3
    else:
        obs[i]['LI'] = 0

LONs=[ob['LON'] for ob in obs if ob['LON'] is not None]
LONd=[(get_ob_date(ob)-startdate).total_seconds() for ob in obs \
                                       if ob['LON'] is not None]
LON_if=scipy.interpolate.interp1d(LONd,LONs)
for i in range(len(obs)):
    if obs[i]['LON'] is None:
        if dates[i]>max(LONd) or dates[i]<min(LONd):
            continue
        obs[i]['LON'] = LON_if(dates[i])
        obs[i]['LI'] = 3
    else:
        obs[i]['LI'] = 0


opfile=open(args.output,'wb')
for ob in obs:
    IMMA.write(ob,opfile)
