# Remake IMMA, KML and diagnostics for the Nimrod expedition

# Convert to IMMA
./Endurance_to_imma.perl < ../as_digitised/ENDURANCE_1914-1915.txt | imma_interpolate.perl > ../../../imma/Endurance_1914-16.imma


# Make the KML
cat ../../../imma/Endurance_1914-16.imma | imma_to_kml.perl --title="Endurance 1914-16" --at  --ice   > ../../../kml/Endurance_1914-16.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Endurance_1914-16.imma > ../../../ovn/Endurance_1914-16.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Endurance_1914-16.imma > ../../../ovn/Endurance_1914-16.ice_range_1979-2004

ln -sf ../../../ovn/Endurance_1914-16.ovn ovn.out
ln -sf ../../../ovn/Endurance_1914-16.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1914-16.pdf
mv ../figures/AT.pdf ../figures/AT_1914-16.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1914-16.pdf
mv ../figures/SLP.pdf ../figures/SLP_1914-16.pdf

