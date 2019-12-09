./pa_to_imma.py   # creates raw.imma
./imma_interpolate.py --input=raw.imma --output=../../../imma/Princesse_Alice_1898.imma
rm raw.imma

cd ../analyses/route_map
./route.py

cd ../20CRv3_comparisons
# Data extraction is slow, and the v3 data must have been downloaded first
./get_comparators.py --imma=../../../../imma/Princesse_Alice_1898.imma --var=PRMSL

./plot_pressure_comparison.py




