# Remake IMMA, KML and diagnostics for the Astrolabe 1837-40

# Convert to IMMA
./astrolabe_to_imma.perl < ../as_digitised/ASTROLOBE_AND_ZELEE_VOYAGES_-_1837.txt | imma_interpolate.perl > ../../../imma/Astrolabe+Zelee_1837-40.imma

# Make the KML
imma_to_kml.perl --title="Astrolabe & Zelee 1837-6" --at --sst --ice --colourby=at < ../../../imma/Astrolabe+Zelee_1837-40.imma > ../../../kml/Astrolabe+Zelee_1837-40.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Astrolabe+Zelee_1837-40.imma > ../../../ovn/Astrolabe+Zelee_1837-40.ovn
ln -sf ../../../ovn/Astrolabe+Zelee_1837-40.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

