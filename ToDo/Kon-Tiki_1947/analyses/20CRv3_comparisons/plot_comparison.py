#!/usr/bin/env python

# Plot a comparison of a set of ship obs against 20CRv3

# Requires 20CR data to have already been extracted with get_comparators.py

import pickle
import imma

import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--imma", help="Ship imma file",
                    type=str,required=True)
parser.add_argument("--pkl", help="20CR pickled data",
                    type=str,required=True)
parser.add_argument("--var", help="IMMA Variable",
                    type=str,required=True)
args = parser.parse_args()

# Load the data to plot
obs=IMMA.read(args.imma)
rdata=pickle.load(open(args.pkl,'rb'))
ob_dates=([datetime.datetime(o['YR'],o['MO'],o['DY'],int(o['HR'])) 
                  for o in obs if 
                (o['YR'] is not None and
                 o['MO'] is not None and
                 o['DY'] is not None and
                 o['HR'] is not None)])
                 
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
ax_scp=fig.add_axes([0,0,1,1])

# Ensemble values - one point for each member at each time-point
for i in rdata:
    ensemble=[v/100.0 for v in i[3]] # in hPa
    ax.scatter([i[0]*len(ensemble),ensemble),
                    5,
                    'blue', # Color
                    marker='.',
                    edgecolors='black',
                    linewidths=0.0,
                    alpha=1.0,
                    zorder=50)

    



