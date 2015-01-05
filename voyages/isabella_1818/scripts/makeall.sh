# Remake IMMA, KML and diagnostics for the Isabella NWP expedition

# Convert to IMMA
isabella_to_imma.perl < ../as_digitised/ADM_55_82_Isabella_0397_0625.txt | imma_interpolate.perl > ../../../imma/Isabella_1818.imma

# Make the KML
cat ../../../imma/Isabella_1818.imma | imma_to_kml.perl --title="Isabella 1818" --at --ws --ice > ../../../kml/Isabella_1818.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Isabella_1818.imma > ../../../ovn/Isabella_1818.ovn
obs_v_ice.perl < ../../../imma/Isabella_1818.imma > ../../../ovn/Isabella_1818.ice_range_1979-2004

ln -sf ../../../ovn/Isabella_1818.ovn ovn.out
ln -sf ../../../ovn/Isabella_1818.ice_range_1979-2004 ice_range_1979-2004.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_AT_I.R > /dev/null
R --no-save < ../../../utilities/plot_SLP.R > /dev/null
R --no-save < ../../../utilities/plot_WS.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null
