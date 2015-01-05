# Remake IMMA, KML and diagnostics for the Favorite 1830-2

# Convert to IMMA
./favorite_to_imma.perl < ../as_digitised/VOYAGE_OF_THE_LA_FAVORITE-1830-1832.txt > ../../../imma/Favorite_1830-2.imma

# Make the KML
imma_to_kml.perl --title="Favorite 1830-2" --at --ice --colourby=at < ../../../imma/Favorite_1830-2.imma > ../../../kml/Favorite_1830-2.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Favorite_1830-2.imma > ../../../ovn/Favorite_1830-2.ovn
ln -sf ../../../ovn/Favorite_1830-2.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

