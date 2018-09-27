# Remake IMMA, KML and diagnostics for the Potomac 1833-4

# Convert to IMMA
./potomac_to_imma.perl < ../as_digitised/USS_POTOMAC-CHILE_TO_BOSTON_1833-34.txt | imma_interpolate.perl > ../../../imma/Potomac_1833-4.imma

# Make the KML
imma_to_kml.perl --title="Potomac 1833-4" --at --colourby=at < ../../../imma/Potomac_1833-4.imma > ../../../kml/Potomac_1833-4.kml


# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Potomac_1833-4.imma > ../../../ovn/Potomac_1833-4.ovn
ln -sf ../../../ovn/Potomac_1833-4.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

