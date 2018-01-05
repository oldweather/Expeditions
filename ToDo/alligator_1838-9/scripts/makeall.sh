# Remake IMMA, KML and diagnostics for the Alligator 1838-9

# Convert to IMMA
./alligator_to_imma.perl < ../as_digitised/HMS_ALLIGATOR_PORT_ESSINGTON_1838-1839.txt | imma_interpolate.perl > ../../../imma/Alligator_1838-9.imma

# Make the KML
imma_to_kml.perl --title="Alligator 1838-9" --at --colourby=at < ../../../imma/Alligator_1838-9.imma > ../../../kml/Alligator_1838-9.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Alligator_1838-9.imma > ../../../ovn/Alligator_1838-9.ovn
ln -sf ../../../ovn/Alligator_1838-9.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

