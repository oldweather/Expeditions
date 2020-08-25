#!/usr/bin/env python

# Show the route of the First Fleet

import os
import math
import datetime
import numpy
import pandas

import iris
import iris.analysis

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg as FigureCanvas
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
parser.add_argument("--year", help="Year", type=int, required=True)
parser.add_argument("--month", help="Integer month", type=int, required=True)
parser.add_argument("--day", help="Day of month", type=int, required=True)
parser.add_argument(
    "--hour", help="Time of day (0 to 23.99)", type=float, required=True
)
parser.add_argument(
    "--opdir",
    help="Directory for output files",
    default="%s/images/FirstFleet" % os.getenv("SCRATCH"),
    type=str,
    required=False,
)
args = parser.parse_args()
if not os.path.isdir(args.opdir):
    os.makedirs(args.opdir)

dte = datetime.datetime(
    args.year, args.month, args.day, int(args.hour), int(args.hour % 1 * 60)
)


# HD video size 1920x1080
aspect = 16.0 / 9.0
fig = Figure(
    figsize=(10.8 * aspect, 10.8),  # Width, Height (inches)
    dpi=100,
    facecolor=(0.88, 0.88, 0.88, 1),
    edgecolor=None,
    linewidth=0.0,
    frameon=False,
    subplotpars=None,
    tight_layout=None,
)
canvas = FigureCanvas(fig)
font = {"family": "sans-serif", "sans-serif": "Arial", "weight": "normal", "size": 14}
matplotlib.rc("font", **font)

# Centred projection
projection = ccrs.RotatedPole(pole_longitude=180, pole_latitude=90)
extent = [-180, 180, -90, 90]

# Map plot
ax_map = fig.add_axes([0.0, 0.0, 1.0, 1.0], projection=projection)
ax_map.set_axis_off()
ax_map.set_extent(extent, crs=projection)
# Lat:Lon aspect does not match the plot aspect, ignore this and
#  fill the figure with the plot.
matplotlib.rc("image", aspect="auto")

# Background, grid and land
ax_map.background_patch.set_facecolor((0.88, 0.88, 0.88, 1))
mg.background.add_grid(ax_map, sep_minor=1, sep_major=5, color=(0, 0.3, 0, 0.2))
land_img = ax_map.background_img(name="GreyT", resolution="low")

# Plot the current position
obs = IMMA.read(
    os.path.join(os.path.dirname(__file__), "../../../imma/First_Fleet_1787-8.imma")
)
for ob in obs:
    if ob["LAT"] is None:
        continue
    if ob["LON"] is None:
        continue
    if ob["YR"] is None:
        continue
    if ob["MO"] is None:
        continue
    if ob["DY"] is None:
        continue
    if ob["HR"] is None:
        continue
    ob_dte = datetime.datetime(ob["YR"], ob["MO"], ob["DY"], int(ob["HR"]))
    if ob_dte < dte:
        rp = ax_map.projection.transform_points(
            ccrs.PlateCarree(), numpy.array(ob["LON"]), numpy.array(ob["LAT"])
        )
        ax_map.add_patch(
            matplotlib.patches.Circle(
                (rp[:, 0], rp[:, 1]),
                radius=0.6,
                facecolor="grey",
                edgecolor="grey",
                alpha=1.0,
                zorder=100,
            )
        )
    if (
        ob_dte - datetime.timedelta(hours=12) < dte
        and ob_dte + datetime.timedelta(hours=12) > dte
    ):
        rp = ax_map.projection.transform_points(
            ccrs.PlateCarree(), numpy.array(ob["LON"]), numpy.array(ob["LAT"])
        )
        ax_map.add_patch(
            matplotlib.patches.Circle(
                (rp[:, 0], rp[:, 1]),
                radius=0.6,
                facecolor="red",
                edgecolor="red",
                alpha=1.0,
                zorder=100,
            )
        )

mg.utils.plot_label(
    ax_map,
    ("%04d-%02d-%02d" % (args.year, args.month, args.day)),
    facecolor=fig.get_facecolor(),
    x_fraction=0.97,
    y_fraction=0.95,
    fontsize=16,
    horizontalalignment="right",
    verticalalignment="top",
)

# Output as png
fig.savefig(
    "%s/%04d%02d%02d%02d.png"
    % (args.opdir, args.year, args.month, args.day, int(args.hour))
)
