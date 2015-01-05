# Remake IMMA, KML and diagnostics for the Investigator 1801-3

# Convert to IMMA
./investigator_to_imma.perl < ../as_digitised/FLINDERS_PERSONAL_JOURNAL_-_1801-1802.txt | imma_interpolate.perl > ../../../imma/Investigator_1801-3.imma

# Make the KML
imma_to_kml.perl --title="Investigator 1801-3" --at --sst --colourby=at < ../../../imma/Investigator_1801-3.imma > ../../../kml/Investigator_1801-3.kml
# Show corrected and uncorrected longitudes
#cat ../../../imma/Investigator_1801-3.imma ../extras/uncorrected.imma | imma_to_kml.perl --title="Investigator 1801-3" > ../../../kml/Investigator_1801-3+corrections.kml

# make the diagnostic figures
../../../../scripts/obs_v_normals.perl < ../../../imma/Investigator_1801-3.imma > ../../../ovn/Investigator_1801-3.ovn
ln -sf ../../../ovn/Investigator_1801-3.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

