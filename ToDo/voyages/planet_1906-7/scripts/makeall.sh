cat ../as_digitised/PLANET2_VOYAGE-1906-1907.txt | ./planet_to_imma.perl | imma_interpolate.perl > ../../../imma/Planet_1906-7.imma

cd ../analyses/route_map
./route.py

cd ../analyses/20CRv3_comparisons
# The v3 data must have been downloaded first
./make_all_comparators.py
spice_parallel --time=5 < run.txt

./plot_pressure_comparison.py
./plot_AT_comparison.py
./plot_SST_comparison.py
