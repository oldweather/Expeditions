# Remake IMMA, KML and diagnostics for the Banzare expedition

# Convert to IMMA
banzare_to_imma.perl < ../as_digitised/DISCOVERY_VOYAGE_1_1929_1930.txt | imma_interpolate.perl > ../../../imma/Discovery_1929-30.imma
banzare_to_imma.perl < ../as_digitised/DISCOVERY_VOYAGE_2_1930_1931.txt | imma_interpolate.perl > ../../../imma/Discovery_1930-31.imma

# Make the KML
cat ../../../imma/Discovery_1929-30.imma | imma_to_kml.perl --title="Discovery 1929-30" --at  --ice   > ../../../kml/Discovery_1929-30.kml
cat ../../../imma/Discovery_1930-31.imma | imma_to_kml.perl --title="Discovery 1930-31" --at  --ice   > ../../../kml/Discovery_1930-31.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Discovery_1929-30.imma > ../../../ovn/Discovery_1929-30.ovn
obs_v_normals.perl < ../../../imma/Discovery_1930-31.imma > ../../../ovn/Discovery_1930-31.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Discovery_1929-30.imma > ../../../ovn/Discovery_1929-30.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Discovery_1930-31.imma > ../../../ovn/Discovery_1930-31.ice_range_1979-2004

ln -sf ../../../ovn/Discovery_1929-30.ovn ovn.out
ln -sf ../../../ovn/Discovery_1929-30.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1929-30.pdf
mv ../figures/AT.pdf ../figures/AT_1929-30.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1929-30.pdf
mv ../figures/SLP.pdf ../figures/SLP_1929-30.pdf
mv ../figures/SST.pdf ../figures/SST_1929-30.pdf

ln -sf ../../../ovn/Discovery_1930-31.ovn ovn.out
ln -sf ../../../ovn/Discovery_1930-31.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1930-31.pdf
mv ../figures/AT.pdf ../figures/AT_1930-31.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1930-31.pdf
mv ../figures/SLP.pdf ../figures/SLP_1930-31.pdf
mv ../figures/SST.pdf ../figures/SST_1930-31.pdf

