# Remake IMMA, KML and diagnostics for the Hecla 1821 NWP expedition

# Convert to IMMA
cat ../as_digitised/ADM_55_65_Hecla_0005_0074.txt ../as_digitised/ADM_55_66_Hecla_0144_0308_2.txt | hecla_to_imma.perl  | imma_interpolate.perl > ../../../imma/Hecla_1821-3.imma

# Make the KML
cat ../../../imma/Hecla_1821-3.imma | imma_to_kml.perl --title="Hecla 1821-3" --at --ws --ice > ../../../kml/Hecla_1821-3.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Hecla_1821-3.imma > ../../../ovn/Hecla_1821-3.ovn
obs_v_ice.perl < ../../../imma/Hecla_1821-3.imma > ../../../ovn/Hecla_1821-3.ice_range_1979-2004

ln -sf ../../../ovn/Hecla_1821-3.ovn ovn.out
ln -sf ../../../ovn/Hecla_1821-3.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null
