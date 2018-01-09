# Remake IMMA, KML and diagnostics for the Alligator 1838-9

# Convert to IMMA
./alligator_to_imma.perl < ../as_digitised/HMS_ALLIGATOR_PORT_ESSINGTON_1838-1839.txt | imma_interpolate.perl > ../../../imma/Alligator_1838-9.imma

# Get comparison data from 20CR normals
R --no-save < 20cr_compare_normal.R

# Plot the route
R --no-save < Route_map.R

# Plot the variables
R --no-save < normals_plot.R


