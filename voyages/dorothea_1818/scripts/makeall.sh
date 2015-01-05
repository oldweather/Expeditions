# Remake IMMA, KML and diagnostics for the Dorothea NWP expedition

# Convert to IMMA
dorothea_to_imma.perl < ../as_digitised/ADM_55_36_HMS_Dorothea_0519_682.txt | imma_interpolate.perl > ../../../imma/Dorothea_1818.imma

# Make the KML
cat ../../../imma/Dorothea_1818.imma | imma_to_kml.perl --title="Dorothea 1818" --at --ws --ice > ../../../kml/Dorothea_1818.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Dorothea_1818.imma > ../../../ovn/Dorothea_1818.ovn
obs_v_ice.perl < ../../../imma/Dorothea_1818.imma > ../../../ovn/Dorothea_1818.ice_range_1979-2004

ln -sf ../../../ovn/Dorothea_1818.ovn ovn.out
ln -sf ../../../ovn/Dorothea_1818.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null
