# Remake IMMA, KML and diagnostics for the Resolution 1772-5

# Convert to IMMA
cook1_to_imma.perl < ../as_digitised/COOK_1-_RESOLUTION.txt | imma_interpolate.perl > ../../../imma/Resolution_C_1772-5.imma
wales1_to_imma.perl < ../as_digitised/COOK-WILLIAM_WALES_JOURNAL_ON_RESOLUTION-1772-1774.txt | imma_interpolate.perl > ../../../imma/Resolution_W1_1772-4.imma
wales2_to_imma.perl < ../as_digitised/COOK-WILLIAM_WALES_JOURNAL_ON_RESOLUTION-1772-1774.txt | imma_interpolate.perl > ../../../imma/Resolution_W2_1772-4.imma

# Make the KML
cat ../../../imma/Resolution_C_1772-5.imma ../../../imma/Resolution_W1_1772-4.imma ../../../imma/Resolution_W2_1772-4.imma | imma_to_kml.perl --title="Resolution 1772-5" --at --ice  > ../../../kml/Resolution_1772-5.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Resolution_C_1772-5.imma > ../../../ovn/Resolution_C_1772-5.ovn
obs_v_normals.perl < ../../../imma/Resolution_W1_1772-4.imma > ../../../ovn/Resolution_W1_1772-4.ovn
obs_v_normals.perl < ../../../imma/Resolution_W2_1772-4.imma > ../../../ovn/Resolution_W2_1772-4.ovn

ln -sf ../../../ovn/Resolution_C_1772-5.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < plot_AT.R > /dev/null
R --no-save < plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null

