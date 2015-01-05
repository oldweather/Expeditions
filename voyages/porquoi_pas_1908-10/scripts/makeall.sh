# Remake IMMA, KML and diagnostics for the Porquoi-Pas expedition

# Convert to IMMA
PqP_to_imma.perl < ../as_digitised/DEUXIEME_EXPEDITION.txt > tmp.imma
PqP_to_imma2.perl < ../as_digitised/MANCHE_TO_CAPE_HORN.txt > tmp2.imma
cat tmp.imma tmp2.imma | imma_sort_by_date.perl | imma_interpolate.perl > ../../../imma/Porquoi_Pas_1908-10.imma
rm tmp.imma tmp2.imma
PqP_to_imma3.perl < ../as_digitised/PETERMANN_ISLAND1909.txt | imma_interpolate.perl > ../../../imma/PqP_PetermanI_1909.imma

# Make the KML
cat ../../../imma/Porquoi_Pas_1908-10.imma | imma_to_kml.perl --title="Porquoi Pas 1908-10" --at  --ice   > ../../../kml/Porquoi_Pas_1908-10.kml
cat ../../../imma/PqP_PetermanI_1909.imma | imma_to_kml.perl --title="PqP Peterman Island" --at  --ice   > ../../../kml/PqP_PetermanI_1909.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Porquoi_Pas_1908-10.imma > ../../../ovn/Porquoi_Pas_1908-10.ovn
obs_v_normals.perl < ../../../imma/PqP_PetermanI_1909.imma > ../../../ovn/PqP_PetermanI_1909.ovn
../../../../scripts/obs_v_ice.perl <../../../imma/Porquoi_Pas_1908-10.imma > ../../../ovn/Porquoi_Pas_1908-10.ice_range_1979-2004
../../../../scripts/obs_v_ice.perl <../../../imma/PqP_PetermanI_1909.imma > ../../../ovn/PqP_PetermanI_1909.ice_range_1979-2004

ln -sf ../../../ovn/Porquoi_Pas_1908-10.ovn ovn.out
ln -sf ../../../ovn/Porquoi_Pas_1908-10.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1908-10.pdf
mv ../figures/AT.pdf ../figures/AT_1908-10.pdf
mv ../figures/AT+I.pdf ../figures/AT+I_1908-10.pdf
mv ../figures/SLP.pdf ../figures/SLP_1908-10.pdf

ln -sf ../../../ovn/PqP_PetermanI_1909.ovn ovn.out
ln -sf ../../../ovn/PqP_PetermanI_1909.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_PI_1909.pdf
mv ../figures/SLP.pdf ../figures/SLP_PI_1909.pdf

