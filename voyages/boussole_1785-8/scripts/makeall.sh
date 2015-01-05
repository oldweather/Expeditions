# Remake IMMA, KML and diagnostics for the Boussole 1785-88

# Convert to IMMA
boussole_to_imma.perl < ../as_digitised/VOYAGE_DE_LA_PEROUSE_ON_THE_BOUSSOLE_1785-1788.txt | imma_interpolate.perl > ../../../imma/Boussole_1785-88.imma

# Make the KML
cat ../../../imma/Boussole_1785-88.imma | imma_to_kml.perl --title="Boussole 1785-88" --at   > ../../../kml/Boussole_1785-88.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Boussole_1785-88.imma > ../../../ovn/Boussole_1785-88.ovn

ln -sf ../../../ovn/Boussole_1785-88.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null

