# Remake IMMA, KML and diagnostics for the Beagle 1831-6

# Convert to IMMA
./beagle_to_imma.perl < ../as_digitised/BEAGLE_AND_ADVENTURE_VOYAGES_-_1826-1836.txt | imma_interpolate.perl > ../../../imma/Beagle_1831-6.imma

# Make the KML
imma_to_kml.perl --title="Beagle 1831-6" --at --sst --colourby=at < ../../../imma/Beagle_1831-6.imma > ../../../kml/Beagle_1831-6.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Beagle_1831-6.imma > ../../../ovn/Beagle_1831-6.ovn
ln -sf ../../../ovn/Beagle_1831-6.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null

R --no-save < ../../../utilities/plot_AT.R > /dev/null

R --no-save < ../../../utilities/plot_SLP.R > /dev/null

R --no-save < ../../../utilities/plot_SST.R > /dev/null

