# Remake IMMA, KML and diagnostics for the Challenger 1872-6

# Convert to IMMA
./challenger_to_imma.perl < ../as_digitised/CHALLENGER_VOYAGE.txt | imma_interpolate.perl > ../../../imma/Challenger_1872-6.imma

# Make the KML
imma_to_kml.perl --title="Challenger 1872-6" --at --sst --colourby=at < ../../../imma/Challenger_1872-6.imma > ../../../kml/Challenger_1872-6.kml

# Make KML comparing Challenger with IMMA data
cat ../../../imma/Challenger_1872-6.imma ../extras/icoads.imma | imma_to_kml.perl --title="Challenger and nearby ICOADS" --nolines > ../../../kml/Challenger+icoads.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Challenger_1872-6.imma > ../../../ovn/Challenger_1872-6.ovn
ln -sf ../../../ovn/Challenger_1872-6.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

