# Remake IMMA, KML and diagnostics for the Nimrod expedition

# Convert to IMMA
./Endurance_to_imma.perl < ../as_digitised/ENDURANCE_1914-1915.txt | imma_interpolate.perl > ../../../imma/Endurance_1914-16.imma
./Aurora_to_imma.perl | imma_interpolate.perl > ../../../imma/Aurora_1914-16.imma
./James_Caird_to_imma.perl < ../as_digitised/JAMES_CAIRD_LOG-APRIL-MAY_1916.txt | imma_interpolate.perl > ../../../imma/James_Caird_1916.imma
./Emma+Yelcho_to_imma.perl < ../as_digitised/SHACKLETON_RELIEF_EXPEDITION-JULY_TO_AUGUST_1916.txt | imma_interpolate.perl > ../../../imma/Emma+Yelcho_1916.imma
