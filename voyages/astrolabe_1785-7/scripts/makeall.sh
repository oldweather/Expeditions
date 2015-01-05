# Remake IMMA, KML and diagnostics for the Astrolabe 1785-87

# Convert to IMMA
astrolabe_to_imma.perl < ../as_digitised/VOYAGE_DE_LA_PEROUSE_ON_THE_ASTROLOBE_1785-1787.txt | imma_interpolate.perl > ../../../imma/Astrolabe_1785-87.imma

# Make the KML
cat ../../../imma/Astrolabe_1785-87.imma | imma_to_kml.perl --title="Astrolabe 1785-87" --at   > ../../../kml/Astrolabe_1785-87.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Astrolabe_1785-87.imma > ../../../ovn/Astrolabe_1785-87.ovn

ln -sf ../../../ovn/Astrolabe_1785-87.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

