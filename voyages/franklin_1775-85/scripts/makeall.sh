# Remake IMMA, KML and diagnostics for the Franklin voyages

# Convert to IMMA
Franklin_to_imma_1775.perl < ../as_digitised/Maritime_Observations_-_APS_1775.txt | imma_interpolate.perl > ../../../imma/Franklin_1775.imma
Franklin_to_imma_1776.perl < ../as_digitised/Maritime_Observations_-_APS_1776.txt | imma_interpolate.perl > ../../../imma/Franklin_1776.imma
Franklin_to_imma_1785.perl < ../as_digitised/Maritime_Observations_-_APS_1785.txt | imma_interpolate.perl > ../../../imma/Franklin_1785.imma

# Make the KML
cat ../../../imma/Franklin_1775.imma | imma_to_kml.perl --title="Franklin 1775" --at --ws --sst  > ../../../kml/Franklin_1775.kml
cat ../../../imma/Franklin_1776.imma | imma_to_kml.perl --title="Franklin 1776" --at --ws --sst  > ../../../kml/Franklin_1776.kml
cat ../../../imma/Franklin_1785.imma | imma_to_kml.perl --title="Franklin 1785" --at --ws --sst  > ../../../kml/Franklin_1785.kml

# make the diagnostic figures
obs_v_normals.perl < ../../../imma/Franklin_1775.imma > ../../../ovn/Franklin_1775.ovn
obs_v_normals.perl < ../../../imma/Franklin_1776.imma > ../../../ovn/Franklin_1776.ovn
obs_v_normals.perl < ../../../imma/Franklin_1785.imma > ../../../ovn/Franklin_1785.ovn

ln -sf ../../../ovn/Franklin_1775.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1775.pdf
mv ../figures/AT.pdf ../figures/AT_1775.pdf
mv ../figures/SST.pdf ../figures/SST_1775.pdf

ln -sf ../../../ovn/Franklin_1776.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1776.pdf
mv ../figures/AT.pdf ../figures/AT_1776.pdf
mv ../figures/SST.pdf ../figures/SST_1776.pdf

ln -sf ../../../ovn/Franklin_1785.ovn ovn.out

R --no-save < ../../../utilities/plot_voyage.R > /dev/null
R --no-save < ../../../utilities/plot_AT.R > /dev/null
R --no-save < ../../../utilities/plot_SST.R > /dev/null

mv ../figures/voyage.pdf ../figures/voyage_1785.pdf
mv ../figures/AT.pdf ../figures/AT_1785.pdf
mv ../figures/SST.pdf ../figures/SST_1785.pdf
