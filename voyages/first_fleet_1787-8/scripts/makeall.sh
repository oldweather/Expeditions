# Remake IMMA, KML and diagnostics for the First Fleet
# Lots of supplemental diagnostics for this one - there's
# a paper in Weather on it.

# Convert to IMMA
ff_to_imma.perl < ../as_digitised/William_Bradley_s_First_Fleet_ship_log_Sirius_1787-1788.txt | imma_interpolate.perl > ../../../imma/First_Fleet_1787-8.imma
ff_supplemental_to_imma.perl < ../as_digitised/William_Bradley_s_First_Fleet_ship_log_Sirius_1787-1788_supplement.txt | imma_interpolate.perl >> ../../../imma/First_Fleet_1787-8.imma

# Make the KML
cat ../../../imma/First_Fleet_1787-8.imma | imma_to_kml.perl --title="First Fleet 1787-8" --at --ws --colourby=at  > ../../../kml/First_Fleet_1787-8.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/First_Fleet_1787-8.imma > ../../../ovn/First_Fleet_1787-8.ovn

ln -sf ../../../ovn/First_Fleet_1787-8.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < plotall.R > /dev/null
