# Remake IMMA, KML and diagnostics for the Adventure 1773-4

# Convert to IMMA
cook2_to_imma.perl < ../as_digitised/COOK_1-_ADVENTURE.txt | imma_interpolate.perl > ../../../imma/Adventure_1773-4.imma

# Make the KML
cat ../../../imma/Adventure_1773-4.imma | imma_to_kml.perl --title="Adventure 1773-4" --at --ice  > ../../../kml/Adventure_1773-4.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Adventure_1773-4.imma > ../../../ovn/Adventure_1773-4.ovn

ln -sf ../../../ovn/Adventure_1773-4.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null

