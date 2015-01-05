# Remake IMMA, KML and diagnostics for the Scotia expedition

# Convert to IMMA
scotia_to_imma.perl < ../as_digitised/SCOTIA_VOYAGE_1902-1903.txt | imma_interpolate.perl > ../../../imma/Scotia_1902-3.imma
scotia_to_imma2.perl < ../as_digitised/SCOTIA_VOYAGE_1903-1904.txt | imma_interpolate.perl > ../../../imma/Scotia_1903-4.imma

# Make the KML
cat ../../../imma/Scotia_1902-3.imma | imma_to_kml.wholeday.perl --title="Scotia 1902-3" --at --ws --ice   > ../../../kml/Scotia_1902-3.kml
cat ../../../imma/Scotia_1903-4.imma | imma_to_kml.wholeday.perl --title="Scotia 1903-4" --at --ws --ice  > ../../../kml/Scotia_1903-4.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Scotia_1902-3.imma > ../../../ovn/Scotia_1902-3.ovn
obs_v_normals.perl < ../../../imma/Scotia_1903-4.imma > ../../../ovn/Scotia_1903-4.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Scotia_1902-3.imma > ../../../ovn/Scotia_1902-3.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Scotia_1903-4.imma > ../../../ovn/Scotia_1903-4.ice_range_1979-2004

ln -sf ../../../ovn/Scotia_1902-3.ovn ovn.out
ln -sf ../../../ovn/Scotia_1902-3.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../diagnostics/plot_AT.R > /dev/null
R --no-save < ../diagnostics/plot_AT_I.R > /dev/null
R --no-save < ../diagnostics/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_2-3.pdf
mv ../figures/AT.pdf ../figures/AT_2-3.pdf
mv ../figures/SLP.pdf ../figures/SLP_2-3.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_2-3.pdf

ln -sf ../../../ovn/Scotia_1903-4.ovn ovn.out
ln -sf ../../../ovn/Scotia_1903-4.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../diagnostics/plot_AT.R > /dev/null
R --no-save < ../diagnostics/plot_AT_I.R > /dev/null
R --no-save < ../diagnostics/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_3-4.pdf
mv ../figures/AT.pdf ../figures/AT_3-4.pdf
mv ../figures/SLP.pdf ../figures/SLP_3-4.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_3-4.pdf


