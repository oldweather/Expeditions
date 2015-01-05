# Remake IMMA, KML and diagnostics for the Resolution 1779-80

# Convert to IMMA
cook1_resolution_to_imma.perl < ../as_digitised/COOK_2_RESOLUTION.txt | imma_interpolate.perl > ../../../imma/Resolution_1779-80.imma
cook2_resolution_to_imma.perl < ../as_digitised/COOK_2_RESOLUTION.txt | imma_interpolate.perl > ../../../imma/Resolution_1779-80_b.imma

# Make the KML
cat ../../../imma/Resolution_1779-80.imma ../../../imma/Resolution_1779-80_b.imma | imma_to_kml.perl --title="Resolution 1779-80" --at --ice --startcolour=9 > ../../../kml/Resolution_1779-80.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Resolution_1779-80.imma > ../../../ovn/Resolution_1779-80.ovn
obs_v_normals.perl < ../../../imma/Resolution_1779-80_b.imma > ../../../ovn/Resolution_1779-80_b.ovn

ln -sf ../../../ovn/Resolution_1779-80.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null

