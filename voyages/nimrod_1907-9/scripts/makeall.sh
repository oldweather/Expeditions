# Remake IMMA, KML and diagnostics for the Nimrod expedition

# Convert to IMMA
Nimrod_to_imma.perl < ../as_digitised/NIMROD_VOYAGE_I.txt | imma_interpolate.perl > ../../../imma/Nimrod_1907-8.imma
Nimrod_to_imma.perl < ../as_digitised/NIMROD_VOYAGE_II.txt | imma_interpolate.perl > ../../../imma/Nimrod_1908-9.imma

# Make the KML
cat ../../../imma/Nimrod_1907-8.imma | imma_to_kml.perl --title="Nimrod 1907-8" --at  --ice   > ../../../kml/Nimrod_1907-8.kml
cat ../../../imma/Nimrod_1908-9.imma | imma_to_kml.perl --title="Nimrod 1908-9" --at  --ice   > ../../../kml/Nimrod_1908-9.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Nimrod_1907-8.imma > ../../../ovn/Nimrod_1907-8.ovn
obs_v_normals.perl < ../../../imma/Nimrod_1908-9.imma > ../../../ovn/Nimrod_1908-9.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Nimrod_1907-8.imma > ../../../ovn/Nimrod_1907-8.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Nimrod_1908-9.imma > ../../../ovn/Nimrod_1908-9.ice_range_1979-2004

ln -sf ../../../ovn/Nimrod_1907-8.ovn ovn.out
ln -sf ../../../ovn/Nimrod_1907-8.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1907-8.pdf
mv ../figures/AT.pdf ../figures/AT_1907-8.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1907-8.pdf
mv ../figures/SLP.pdf ../figures/SLP_1907-8.pdf

ln -sf ../../../ovn/Nimrod_1908-9.ovn ovn.out
ln -sf ../../../ovn/Nimrod_1908-9.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1908-9.pdf
mv ../figures/AT.pdf ../figures/AT_1908-9.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1908-9.pdf
mv ../figures/SLP.pdf ../figures/SLP_1908-9.pdf

