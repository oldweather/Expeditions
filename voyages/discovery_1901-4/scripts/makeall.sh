# Remake IMMA, KML and diagnostics for the Discovery 1901-4 expedition

# Convert to IMMA
Discovery_to_imma.perl < ../as_digitised/DISCOVERY.txt | imma_interpolate.perl > ../../../imma/Discovery_1901-4.imma

# Make the KML
cat ../../../imma/Discovery_1901-4.imma | imma_to_kml.perl --title="Discovery 1901-4" --at  --ice   > ../../../kml/Discovery_1901-4.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Discovery_1901-4.imma > ../../../ovn/Discovery_1901-4.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Discovery_1901-4.imma > ../../../ovn/Discovery_1901-4.ice_range_1979-2004

ln -sf ../../../ovn/Discovery_1901-4.ovn ovn.out
ln -sf ../../../ovn/Discovery_1901-4.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null


