#!/usr/bin/env python

# Plot a comparison of a set of ship obs against 20CRv3

# Requires 20CR data to have already been extracted with get_comparators.py

import glob

obs_file='../../../../imma/Planet_1906-7.imma'
pickled_20CRdata_files=glob.glob('pickles/20CRv3_air.sfc.*.pkl')

import pickle
import IMMA
import datetime
import numpy

import matplotlib
from matplotlib.backends.backend_agg import \
                 FigureCanvasAgg as FigureCanvas
from matplotlib.figure import Figure

# Load the data to plot
obs=IMMA.read(obs_file)
ob_dates=([datetime.datetime(o['YR'],o['MO'],o['DY'],int(o['HR'])) 
                  for o in obs if 
                (o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
ob_values=[o['SST'] for o in obs if o['SST'] is not None]
rdata=[]
for pkf in pickled_20CRdata_files:
    nrd=pickle.load(open(pkf,'rb'))
    for element in nrd:
       rdata.append(element)
rdata_values=[value-273.15 for ensemble in rdata for value in ensemble[3]]

# Set up the plot
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

# Single axes - var v. time
ax=fig.add_axes([0.05,0.05,0.945,0.94])
# Axes ranges from data
ax.set_xlim((min(ob_dates)-datetime.timedelta(days=1),
             max(ob_dates)+datetime.timedelta(days=1)))
ax.set_ylim((min(min(ob_values),min(rdata_values))-1,
             max(max(ob_values),max(rdata_values))+1))
ax.set_ylabel('Sea-surface temperature (C)')

# Ensemble values - one point for each member at each time-point
t_jitter=numpy.random.uniform(low=-6,high=6,size=len(rdata[0][3]))
for i in rdata:
    ensemble=numpy.array([v-273.15 for v in i[3]]) # in hPa
    dates=[i[0]+datetime.timedelta(hours=t) for t in t_jitter]
    ax.scatter(dates,ensemble,
                    10,
                    'blue', # Color
                    marker='.',
                    edgecolors='black',
                    linewidths=0.0,
                    alpha=0.2,
                    zorder=50)

# Observations
ob_dates=([datetime.datetime(o['YR'],o['MO'],o['DY'],int(o['HR'])) 
                  for o in obs if 
                (o['SST'] is not None and
                 o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
ob_values=([o['SST'] 
                  for o in obs if 
                (o['SST'] is not None and
                 o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
ax.scatter(ob_dates,ob_values,
                100,
                'red', # Color
                marker='.',
                edgecolors='black',
                linewidths=0.0,
                alpha=1.0,
                zorder=100)

fig.savefig('SST_comparison.png')
