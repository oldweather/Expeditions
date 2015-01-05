#!/usr/bin/ksh

# Utility script to regenerate all the figures

../../../../scripts/obs_v_normals.perl < ../../../imma/scoresby_1810-17.imma > ovn.out
../../../../scripts/obs_v_normals.perl < ../../../imma/Scoresby_1822.imma >> ovn.out
../../../../scripts/obs_v_ice.perl < ../../../imma/scoresby_1810-17.imma > ice_range_1979-2004.out
../../../../scripts/obs_v_ice.perl < ../../../imma/Scoresby_1822.imma >> ice_range_1979-2004.out
../../../../scripts/obs_v_at.perl < ../../../imma/scoresby_1810-17.imma > at_range_1979-2004.out
../../../../scripts/obs_v_at.perl < ../../../imma/Scoresby_1822.imma >> at_range_1979-2004.out

R --no-save < plotall.R > /dev/null
epstopdf ../figures/All.ps
convert -geometry 800x600 ../figures/All.ps ../figures/All.png

R --no-save < plot_AT.R > /dev/null
epstopdf ../figures/AT.ps
convert -geometry 800x600 -rotate 90 ../figures/AT.ps ../figures/AT.png

R --no-save < plot_AT_I.R > /dev/null
epstopdf ../figures/AT+I.ps
convert -geometry 800x600 -rotate 90 ../figures/AT+I.ps ../figures/AT+I.png

