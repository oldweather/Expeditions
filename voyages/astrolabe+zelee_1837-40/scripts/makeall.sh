# Remake IMMA, KML and diagnostics for the Astrolabe 1837-40

# Convert to IMMA
./astrolabe_to_imma.perl < ../as_digitised/ASTROLOBE_AND_ZELEE_VOYAGES_-_1837.txt | imma_interpolate.perl > ../../../imma/Astrolabe+Zelee_1837-40.imma

# Get comparison data from 20CR normals
R --no-save < 20cr_compare_normal.R

# Plot the route
R --no-save < Route_map.R

# Plot the variables
R --no-save < normals_plot.R



