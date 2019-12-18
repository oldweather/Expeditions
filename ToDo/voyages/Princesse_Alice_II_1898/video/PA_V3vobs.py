#!/usr/bin/env python

# European region weather plot 
# Compare observations from 20CRV3 and Princesse Alice II
# Video version.

import os
import math
import datetime
import numpy
import pandas

import iris
import iris.analysis

import matplotlib
from matplotlib.backends.backend_agg import \
             FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure

import cartopy
import cartopy.crs as ccrs

import Meteorographica as mg
import IRData.twcr as twcr
import IMMA
import pickle

# Get the datetime to plot from commandline arguments
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--year", help="Year",
                    type=int,required=True)
parser.add_argument("--month", help="Integer month",
                    type=int,required=True)
parser.add_argument("--day", help="Day of month",
                    type=int,required=True)
parser.add_argument("--hour", help="Time of day (0 to 23.99)",
                    type=float,required=True)
parser.add_argument("--opdir", help="Directory for output files",
                    default="%s/images/Princesse_Alice_II_1898" % \
                                           os.getenv('SCRATCH'),
                    type=str,required=False)
args = parser.parse_args()
if not os.path.isdir(args.opdir):
    os.makedirs(args.opdir)

dte=datetime.datetime(args.year,args.month,args.day,
                      int(args.hour),int(args.hour%1*60))


# HD video size 1920x1080
aspect=16.0/9.0
fig=Figure(figsize=(10.8*aspect,10.8),  # Width, Height (inches)
           dpi=100,
           facecolor=(0.88,0.88,0.88,1),
           edgecolor=None,
           linewidth=0.0,
           frameon=False,
           subplotpars=None,
           tight_layout=None)
canvas=FigureCanvas(fig)
font = {'family' : 'sans-serif',
        'sans-serif' : 'Arial',
        'weight' : 'normal',
        'size'   : 14}
matplotlib.rc('font', **font)

# US-centred projection
projection=ccrs.RotatedPole(pole_longitude=180, pole_latitude=30)
scale=25
extent=[scale*-1*aspect/2,scale*1.5*aspect,scale*-1,scale]

# Map plot on the left
ax_map=fig.add_axes([0.01,0.01,0.98,0.98],projection=projection)
ax_map.set_axis_off()
ax_map.set_extent(extent, crs=projection)

# Background, grid and land 
ax_map.background_patch.set_facecolor((0.88,0.88,0.88,1))
mg.background.add_grid(ax_map,sep_minor=1,sep_major=5)
land_img=ax_map.background_img(name='GreyT', resolution='low')

# Add the observations from Reanalysis
obs=twcr.load_observations_fortime(dte,version='3')
mg.observations.plot(ax_map,obs,radius=0.25,edgecolor=(0.2,0.2,0.2),linewidth=0.01)
# Plot the current position
obs=IMMA.read(os.path.join(os.path.dirname(__file__),
                       '../../../imma/Princesse_Alice_II_1898.imma'))
for ob in obs:
    if ob['LAT'] is None: continue
    if ob['LON'] is None: continue
    if ob['YR'] is None: continue
    if ob['MO'] is None: continue
    if ob['DY'] is None: continue
    if ob['HR'] is None: continue
#    if ob['LI'] is not None and ob['LI']==3: continue
    ob_dte=datetime.datetime(ob['YR'],ob['MO'],ob['DY'],int(ob['HR']))
    if ob_dte<dte:
           rp=ax_map.projection.transform_points(ccrs.PlateCarree(),
                                              numpy.array(ob['LON']),
                                              numpy.array(ob['LAT']))
           ax_map.add_patch(matplotlib.patches.Circle((rp[:,0],rp[:,1]),
                                                radius=0.2,
                                                facecolor='grey',
                                                edgecolor='grey',
                                                alpha=1.0,
                                                zorder=100))
    if (ob_dte-datetime.timedelta(hours=1)<=dte and 
        ob_dte+datetime.timedelta(hours=1)>dte):
           rp=ax_map.projection.transform_points(ccrs.PlateCarree(),
                                              numpy.array(ob['LON']),
                                              numpy.array(ob['LAT']))
           ax_map.add_patch(matplotlib.patches.Circle((rp[:,0],rp[:,1]),
                                                radius=0.2,
                                                facecolor='red',
                                                edgecolor='red',
                                                alpha=1.0,
                                                zorder=100))

mg.utils.plot_label(ax_map,
              ('%04d-%02d-%02d:%02d' % 
               (args.year,args.month,args.day,args.hour)),
              facecolor=fig.get_facecolor(),
              x_fraction=0.02,
              horizontalalignment='left')


# Add the pressure timeseries
rdata=pickle.load(open('../analyses/20CRv3_comparisons/20CRv3_PRMSL.pkl','rb'))
ob_dates=([datetime.datetime(o['YR'],o['MO'],o['DY'],int(o['HR'])) 
                  for o in obs if 
                (o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
ob_values=[o['SLP'] for o in obs if o['SLP'] is not None]
rdata_values=[value/100.0 for ensemble in rdata for value in ensemble[3]]
ax_slp=fig.add_axes([0.55-0.005,0.80,0.44,0.18])
# Axes ranges from data
ax_slp.set_xlim((min(ob_dates)-datetime.timedelta(days=1),
             max(ob_dates)+datetime.timedelta(days=1)))
ax_slp.set_ylim((min(min(ob_values),min(rdata_values))-5,
                 max(max(ob_values),max(rdata_values))+5))
ax_slp.set_ylabel('MSLP (hPa)')
ax_slp.get_xaxis().set_visible(True)
t_jitter=numpy.linspace(start=-6,stop=6,num=len(rdata[0][3]))
for i in rdata:
    if i[0]>dte: continue
    ensemble=numpy.array([v/100.0 for v in i[3]]) # in hPa
    dates=[i[0]+datetime.timedelta(hours=t) for t in t_jitter]
    ax_slp.scatter(dates,ensemble,
                    10,
                    'blue', # Color
                    marker='.',
                    edgecolors='blue',
                    linewidths=0.0,
                    alpha=0.1,
                    zorder=50)
ob_dates=([datetime.datetime(o['YR'],o['MO'],o['DY'],int(o['HR'])) 
                  for o in obs if 
                (o['SLP'] is not None and
                 o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
ob_values=([o['SLP'] 
                  for o in obs if 
                (o['SLP'] is not None and
                 o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
indices_past = [i for i in range(len(ob_dates)) if ob_dates[i]<dte]
if len(indices_past)>0:
    ax_slp.scatter([ob_dates[i] for i in indices_past],
                   [ob_values[i] for i in indices_past],
                    50,
                    'black', # Color
                    marker='.',
                    edgecolors='black',
                    linewidths=0.0,
                    alpha=1.0,
                    zorder=100)
    ax_slp.scatter([ob_dates[indices_past[-1]]],
                   [ob_values[indices_past[-1]]],
                    50,
                    'red', # Color
                    marker='.',
                    edgecolors='red',
                    linewidths=0.0,
                    alpha=1.0,
                    zorder=100)


# Output as png
fig.savefig('%s/V3vobs_PAII_%04d%02d%02d%02d%02d.png' % 
               (args.opdir,args.year,args.month,args.day,
                           int(args.hour),int(args.hour%1*60)))
