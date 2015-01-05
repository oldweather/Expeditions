#!/usr/bin/ksh

# Utility script to regenerate all the figures

#../../../../scripts/obs_v_normals.perl < ../../../imma/isabella.imma > ovn.out
../../../../scripts/obs_v_ice.perl < ../../../imma/isabella.imma > ice_range_1979-2004.out
../../../../scripts/obs_v_sst.perl < ../../../imma/isabella.imma > sst_range_1979-2004.out
../../../../scripts/obs_v_at.perl < ../../../imma/isabella.imma > at_range_1979-2004.out
../../../../scripts/obs_v_pre.perl < ../../../imma/isabella.imma > pre_range_1979-2004.out
#./estimate_ice.perl< ../../../imma/isabella.imma >ice_estimates.out

R --no-save < plotall.R > /dev/null 
epstopdf ../figures/All.ps
convert -geometry 800x600 -rotate 0 ../figures/All.ps ../figures/All.png

R --no-save < plot_AT.R > /dev/null
epstopdf ../figures/AT.ps
convert -geometry 800x600 -rotate 90 ../figures/AT.ps ../figures/AT.png

R --no-save < plot_AT_I.R > /dev/null
epstopdf ../figures/AT+I.ps
convert -geometry 800x600 -rotate 90 ../figures/AT+I.ps ../figures/AT+I.png

R --no-save < plot_SST.R > /dev/null
epstopdf ../figures/SST.ps
convert -geometry 800x600 -rotate 90 ../figures/SST.ps ../figures/SST.png

R --no-save < plot_SST_I.R > /dev/null
epstopdf ../figures/SST+I.ps
convert -geometry 800x600 -rotate 90 ../figures/SST+I.ps ../figures/SST+I.png

R --no-save < plot_SLP.R > /dev/null
epstopdf ../figures/SLP.ps
convert -geometry 800x600 -rotate 90 ../figures/SLP.ps ../figures/SLP.png

R --no-save < plot_speed+ice.R > /dev/null
epstopdf ../figures/Ice.ps
convert -geometry 800x600 -rotate 90 ../figures/Ice.ps ../figures/Ice.png

R --no-save < plot_ice_estimates.R > /dev/null
epstopdf ../figures/Ice_estimates.ps
convert -geometry 800x600 -rotate 90 ../figures/Ice_estimates.ps ../figures/Ice_estimates.png
