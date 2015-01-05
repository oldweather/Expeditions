# Remake IMMA, KML and diagnostics for the Southern Cross expedition

# Convert to IMMA
SC_to_imma.perl < ../as_digitised/SOUTHERN_CROSS_STEAM_YACHT.txt | imma_interpolate.perl > ../../../imma/Southern_Cross_1897-1900.imma

# Make the KML
cat ../../../imma/Southern_Cross_1897-1900.imma | imma_to_kml.perl --title="Southern Cross 1897-1900" --at  --ice   > ../../../kml/Southern_Cross_1897-1900.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Southern_Cross_1897-1900.imma > ../../../ovn/Southern_Cross_1897-1900.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Southern_Cross_1897-1900.imma > ../../../ovn/Southern_Cross_1897-1900.ice_range_1979-2004

ln -sf ../../../ovn/Southern_Cross_1897-1900.ovn ovn.out
ln -sf ../../../ovn/Southern_Cross_1897-1900.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null


