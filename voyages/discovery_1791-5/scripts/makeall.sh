#!/usr/bin/ksh

# Make the IMMA and KML, and generate the figures for Vancouver's expedition

discovery_to_imma.perl < ../as_digitised/VANCOUVER.txt | imma_interpolate.perl > ../../../imma/discovery_1791-5.imma
cat ../../../imma/discovery_1791-5.imma | imma_to_kml.perl --title="Discovery 1791-5" --at > ../../../kml/Discovery_1791-5.kml

../../../../scripts/obs_v_normals.perl < ../../../imma/discovery_1791-5.imma > ../../../ovn/discovery_1791-5.ovn
ln -sf ../../../ovn/discovery_1791-5.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

