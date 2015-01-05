# Remake IMMA, KML and diagnostics for the Belgica expedition

# Convert to IMMA
Belgica_to_imma.perl | imma_interpolate.perl > ../../../imma/Belgica_1897-99.imma

# Make the KML
cat ../../../imma/Belgica_1897-99.imma | imma_to_kml.perl --title="Belgica 1897-99" --at  --ice   > ../../../kml/Belgica_1897-99.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Belgica_1897-99.imma > ../../../ovn/Belgica_1897-99.ovn
# Pressures only - don't bothe with the ice ranges

ln -sf ../../../ovn/Belgica_1897-99.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null


