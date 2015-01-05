# Remake IMMA, KML and diagnostics for the Discovery 1776-9

# Convert to IMMA
cook1_discovery_to_imma.perl < ../as_digitised/COOK_2_DISCOVERY.txt | imma_interpolate.perl > ../../../imma/Discovery_1776-9.imma
cook2_discovery_to_imma.perl < ../as_digitised/COOK_2_DISCOVERY.txt | imma_interpolate.perl > ../../../imma/Discovery_1776-9_b.imma

# Make the KML
cat ../../../imma/Discovery_1776-9.imma ../../../imma/Discovery_1776-9_b.imma | imma_to_kml.perl --title="Discovery 1776-9" --at --ice  > ../../../kml/Discovery_1776-9.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Discovery_1776-9.imma > ../../../ovn/Discovery_1776-9.ovn
obs_v_normals.perl < ../../../imma/Discovery_1776-9_b.imma > ../../../ovn/Discovery_1776-9_b.ovn

ln -sf ../../../ovn/Discovery_1776-9.ovn ovn.out

R --no-save < plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null

