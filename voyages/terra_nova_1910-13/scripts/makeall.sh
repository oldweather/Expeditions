# Remake IMMA, KML and diagnostics for the Terra-Nova expedition

# Convert to IMMA
Terra_Nova_to_imma.perl < ../as_digitised/Terra_Nova_voyage_1_Nov1910_March1911.txt | imma_interpolate.perl > ../../../imma/Terra_Nova_1910-11.imma
Terra_Nova_to_imma.perl < ../as_digitised/Terra_Nova_voyage_2_Dec1911_April1912.txt | imma_interpolate.perl > ../../../imma/Terra_Nova_1911-12.imma
Terra_Nova_to_imma.perl < ../as_digitised/Terra_Nova_voyage_3_Dec1912_Feb1913.txt | imma_interpolate.perl > ../../../imma/Terra_Nova_1912-13.imma

# Make the KML
cat ../../../imma/Terra_Nova_1910-11.imma | imma_to_kml.perl --title="Terra Nova1910-11" --at  --ice   > ../../../kml/Terra_Nova_1910-11.kml
cat ../../../imma/Terra_Nova_1911-12.imma | imma_to_kml.perl --title="Terra Nova 1911-12" --at  --ice   > ../../../kml/Terra_Nova_1911-12.kml
cat ../../../imma/Terra_Nova_1912-13.imma | imma_to_kml.perl --title="Terra Nova 1912-13" --at  --ice   > ../../../kml/Terra_Nova_1912-13.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Terra_Nova_1910-11.imma > ../../../ovn/Terra_Nova_1910-11.ovn
obs_v_normals.perl < ../../../imma/Terra_Nova_1911-12.imma > ../../../ovn/Terra_Nova_1911-12.ovn
obs_v_normals.perl < ../../../imma/Terra_Nova_1912-13.imma > ../../../ovn/Terra_Nova_1912-13.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Terra_Nova_1910-11.imma > ../../../ovn/Terra_Nova_1910-11.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Terra_Nova_1911-12.imma > ../../../ovn/Terra_Nova_1911-12.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/Terra_Nova_1912-13.imma > ../../../ovn/Terra_Nova_1912-13.ice_range_1979-2004

ln -sf ../../../ovn/Terra_Nova_1910-11.ovn ovn.out
ln -sf ../../../ovn/Terra_Nova_1910-11.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1910-11.pdf
mv ../figures/AT.pdf ../figures/AT_1910-11.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1910-11.pdf
mv ../figures/SLP.pdf ../figures/SLP_1910-11.pdf

ln -sf ../../../ovn/Terra_Nova_1911-12.ovn ovn.out
ln -sf ../../../ovn/Terra_Nova_1911-12.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1911-12.pdf
mv ../figures/AT.pdf ../figures/AT_1911-12.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1911-12.pdf
mv ../figures/SLP.pdf ../figures/SLP_1911-12.pdf

ln -sf ../../../ovn/Terra_Nova_1912-13.ovn ovn.out
ln -sf ../../../ovn/Terra_Nova_1912-13.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1912-13.pdf
mv ../figures/AT.pdf ../figures/AT_1912-13.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1912-13.pdf
mv ../figures/SLP.pdf ../figures/SLP_1912-13.pdf
