# Remake IMMA, KML and diagnostics for William Scoresby's voyages

# Convert to IMMA
scoresby_to_imma.perl < ../as_digitised/SCORESBY.txt | imma_interpolate.perl > ../../../imma/Scoresby_1810-17.imma
scoresby_to_imma.perl < ../as_digitised/SCORESBY_1822.txt | imma_interpolate.perl > ../../../imma/Scoresby_1822.imma

# Make the KML
cat ../../../imma/Scoresby_1810-17.imma | imma_to_kml.perl --title="Scoresby 1810-17" --at  --ice   > ../../../kml/Scoresby_1810-17.kml
cat ../../../imma/Scoresby_1822.imma | imma_to_kml.perl --title="Scoresby 1822" --at  --ice   > ../../../kml/Scoresby_1822.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Scoresby_1810-17.imma > ../../../ovn/Scoresby_1810-17.ovn
obs_v_normals.perl < ../../../imma/Scoresby_1822.imma > ../../../ovn/Scoresby_1822.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Scoresby_1810-17.imma > ../../../ovn/Scoresby_1810-17.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Scoresby_1822.imma > ../../../ovn/Scoresby_1822.ice_range_1979-2004

ln -sf ../../../ovn/Scoresby_1810-17.ovn ovn.out
ln -sf ../../../ovn/Scoresby_1810-17.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1810-17.pdf
mv ../figures/AT.pdf ../figures/AT_1810-17.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1810-17.pdf

ln -sf ../../../ovn/Scoresby_1822.ovn ovn.out
ln -sf ../../../ovn/Scoresby_1822.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1822.pdf
mv ../figures/AT.pdf ../figures/AT_1822.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1822.pdf

