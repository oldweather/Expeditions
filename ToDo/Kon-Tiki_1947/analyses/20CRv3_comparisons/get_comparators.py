#!/usr/bin/env python

# Extract data from 20CRv3 along the route of a ship.
# For each IMMA record in the input file, get the 
#  selected variable at the same time and place.

import IRData.twcr as twcr
import iris
import iris.analysis
import numpy
import datetime
import IMMA
import pickle
import os

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--imma", help="Ship imma file",
                    type=str,required=True)
parser.add_argument("--var", help="Variable to extract",
                    type=str,required=True)
parser.add_argument("--opdir", help="Directory for output files",
                    default=".",
                    type=str,required=False)
args = parser.parse_args()
if not os.path.isdir(args.opdir):
    os.makedirs(args.opdir)

result=[]
o_source=IMMA.get(args.imma)
for ob in o_source:
    if (ob['YR'] is None or
        ob['MO'] is None or
        ob['DY'] is None or
        ob['HR'] is None): continue
    dte=datetime.datetime(ob['YR'],ob['MO'],ob['DY'],int(ob['HR']))
    rdata=twcr.load(args.var,dte,version='4.5.1')
    if (ob['LAT'] is None or
        ob['LON'] is None): continue
    interpolator = iris.analysis.Linear().interpolator(rdata, 
                                    ['latitude', 'longitude'])
    ensemble = interpolator([numpy.array(ob['LAT']),
                             numpy.array(ob['LON'])]).data
    point=[dte,ob['LAT'],ob['LON'],ensemble]
    result.append(point)

pickle.dump( result, 
             open( "%s/20CRv3_%s.pkl" % (args.opdir,args.var), "wb" ) )
