# Remake IMMA, KML and diagnostics for the Aurora expedition

# Convert to IMMA
Aurora_to_imma.perl < ../as_digitised/AURORA_VOYAGE_CAPETOWN_TO_HOBART.txt | imma_interpolate.perl > ../../../imma/Aurora_1911-14.imma

# Make the KML
cat ../../../imma/Aurora_1911-14.imma | imma_to_kml.perl --title="Aurora 1911-14" --at  --ice   > ../../../kml/Aurora_1911-14.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Aurora_1911-14.imma > ../../../ovn/Aurora_1911-14.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Aurora_1911-14.imma > ../../../ovn/Aurora_1911-14.ice_range_1979-2004

ln -sf ../../../ovn/Aurora_1911-14.ovn ovn.out
ln -sf ../../../ovn/Aurora_1911-14.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null


