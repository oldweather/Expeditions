# Remake IMMA, KML and diagnostics for the Naturaliste 1800-3

# Convert to IMMA
./naturaliste_to_imma.perl < ../as_digitised/VOYAGE_DE_DECOUVERTES_AUX_TERRES_AUSTRALES_1800-1804.txt | imma_interpolate.perl > ../../../imma/Naturaliste_1800-3.imma

# Make the KML
imma_to_kml.perl --title="Naturaliste 1800-3" --at --colourby=at < ../../../imma/Naturaliste_1800-3.imma > ../../../kml/Naturaliste_1800-3.kml

# Make a plain colour KML file for comparison with the investigator
#imma_to_kml.perl --title="Naturaliste 1800-3" --startcolour=8 < ../../../imma/Naturaliste_1800-3.imma > ../../../kml/Naturaliste_1800-3.plaincolour.kml


# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Naturaliste_1800-3.imma > ../../../ovn/Naturaliste_1800-3.ovn
ln -sf ../../../ovn/Naturaliste_1800-3.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

