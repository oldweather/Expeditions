# Remake IMMA, KML and diagnostics for the Hecla 1824 NWP expedition

# Convert to IMMA
cat ../as_digitised/VOYAGE_TO_THE_ARCTIC-1824-1825_THIRD_VOYAGE_PARRY_1824.txt ../as_digitised/VOYAGE_TO_THE_ARCTIC-1824-1825_THIRD_VOYAGE_PARRY_1824+5.txt | hecla_to_imma.perl  | imma_interpolate.perl > ../../../imma/Hecla_1824-5.imma
fury_to_imma.perl < '../as_digitised/ADM_55_56_HMS_Fury_0400_0467_(2).txt' | imma_interpolate.perl > ../../../imma/Fury_1824-5.imma 

# Make the KML
cat ../../../imma/Hecla_1824-5.imma | imma_to_kml.perl --title="Hecla 1824-5" --at --ws --ice > ../../../kml/Hecla_1824-5.kml
cat ../../../imma/Fury_1824-5.imma | imma_to_kml.perl --title="Fury 1824-5" --at --ws --ice > ../../../kml/Fury_1824-5.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Hecla_1824-5.imma > ../../../ovn/Hecla_1824-5.ovn
obs_v_normals.perl < ../../../imma/Fury_1824-5.imma > ../../../ovn/Fury_1824-5.ovn
obs_v_ice.perl < ../../../imma/Hecla_1824-5.imma > ../../../ovn/Hecla_1824-5.ice_range_1979-2004

ln -sf ../../../ovn/Hecla_1824-5.ovn ovn.out
ln -sf ../../../ovn/Fury_1824-5.ovn fury_ovn.out
ln -sf ../../../ovn/Hecla_1824-5.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ./plot_AT.R > /dev/null
R --no-save < ./plot_AT_I.R > /dev/null
R --no-save < ./plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null
