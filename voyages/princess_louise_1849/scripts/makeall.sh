# Remake IMMA, KML and diagnostics for the Princess Louise 1849 (the Schomburgk brothers)

# Convert to IMMA
./pcsl_to_imma.perl < ../as_digitised/Princess_Louise-Hamburg_Adelaide.txt | imma_interpolate.perl > ../../../imma/Princess_Louise_1849.imma

# Make the KML
imma_to_kml.perl --title="Princess Louise 1849" --at --sst --colourby=at < ../../../imma/Princess_Louise_1849.imma > ../../../kml/Princess_Louise_1849.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Princess_Louise_1849.imma > ../../../ovn/Princess_Louise_1849.ovn
ln -sf ../../../ovn/Princess_Louise_1849.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

