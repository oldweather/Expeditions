# Remake IMMA, KML and diagnostics for the Paramour 1969-1700

# Convert to IMMA
./paramore_to_imma.perl < ../as_digitised/Halley_1699.txt > ../../../imma/Paramore_1699-1700.imma

# Make the KML
imma_to_kml.perl --title="Paramore 1699-1700" --at --ice --colourby=at < ../../../imma/Paramore_1699-1700.imma > ../../../kml/Paramore_1699-1700.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Paramore_1699-1700.imma > ../../../ovn/Paramore_1699-1700.ovn
ln -sf ../../../ovn/Paramore_1699-1700.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null

