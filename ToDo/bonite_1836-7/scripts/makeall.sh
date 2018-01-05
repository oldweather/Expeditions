# Remake IMMA, KML and diagnostics for the Bonite 1836-7

# Convert to IMMA
./bonite_to_imma.perl < ../as_digitised/VOYAGE_AUTOUR_DU_MONDE_BONITE_1836.txt | imma_interpolate.perl > ../../../imma/Bonite_1836-7.imma

# Make the KML
imma_to_kml.perl --title="Bonite 1836-7" --at --sst --colourby=at < ../../../imma/Bonite_1836-7.imma > ../../../kml/Bonite_1836-7.kml


# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Bonite_1836-7.imma > ../../../ovn/Bonite_1836-7.ovn
ln -sf ../../../ovn/Bonite_1836-7.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

