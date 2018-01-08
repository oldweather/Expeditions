# Remake IMMA, KML and diagnostics for the Bonite 1836-7

# Convert to IMMA
./bonite_to_imma.perl < ../as_digitised/VOYAGE_AUTOUR_DU_MONDE_BONITE_1836.txt | imma_interpolate.perl > ../../../imma/Bonite_1836-7.imma

# Get comparison data from 20CR normals
R --no-save < 20cr_compare_normal.R

# Plot the route
R --no-save < Route_map.R

# Plot the variables
R --no-save < normals_plot.R
