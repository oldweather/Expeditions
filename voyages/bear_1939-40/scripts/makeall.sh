# Remake IMMA, KML and diagnostics for the Bear 1939-40 expedition

# Convert to IMMA
bear_to_imma.perl < ../as_digitised/USS_BEAR_VOYAGE.txt | imma_interpolate.perl > ../../../imma/Bear_1939-40.imma

# Make the KML
cat ../../../imma/Bear_1939-40.imma | imma_to_kml.perl --title="Bear 1939-40" --at  --ice   > ../../../kml/Bear_1939-40.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Bear_1939-40.imma > ../../../ovn/Bear_1939-40.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Bear_1939-40.imma > ../../../ovn/Bear_1939-40.ice_range_1979-2004

ln -sf ../../../ovn/Bear_1939-40.ovn ovn.out
ln -sf ../../../ovn/Bear_1939-40.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null


