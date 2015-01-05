# Remake IMMA, KML and diagnostics for the Hecla 1819 NWP expedition

# Convert to IMMA
hecla_to_imma.perl < ../as_digitised/VOYAGE_TO_THE_ARCTIC-1819-1820_FIRST_VOYAGE_PARRY.txt | imma_interpolate.perl > ../../../imma/Hecla_1819-20.imma

# Make the KML
cat ../../../imma/Hecla_1819-20.imma | imma_to_kml.perl --title="Hecla 1819-20" --at --ws --ice > ../../../kml/Hecla_1819-20.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Hecla_1819-20.imma > ../../../ovn/Hecla_1819-20.ovn
obs_v_ice.perl < ../../../imma/Hecla_1819-20.imma > ../../../ovn/Hecla_1819-20.ice_range_1979-2004

ln -sf ../../../ovn/Hecla_1819-20.ovn ovn.out
ln -sf ../../../ovn/Hecla_1819-20.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
