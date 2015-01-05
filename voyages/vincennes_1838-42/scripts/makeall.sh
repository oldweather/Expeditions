# Remake IMMA, KML and diagnostics for the Vincennes 1838-42

# Convert to IMMA
./vincennes_to_imma.perl < ../as_digitised/US_EXPLORING_EXPEDITION_-_1838-1842_Complete.txt | imma_interpolate.perl > ../../../imma/Vincennes_1838-42.imma

# Make the KML
imma_to_kml.perl --title="Vincennes 1838-42" --at --sst --colourby=at < ../../../imma/Vincennes_1838-42.imma > ../../../kml/Vincennes_1838-42.kml


# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Vincennes_1838-42.imma > ../../../ovn/Vincennes_1838-42.ovn
ln -sf ../../../ovn/Vincennes_1838-42.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

