cat ../as_digitised/Kon-Tiki.csv | ./kt_to_imma.perl | imma_interpolate.perl > ../../../imma/Kon-Tiki_1947.imma

cd ../analyses/20CRv3_comparisons
# Data extraction is slow, and the v3 data must have been downloaded first
./get_comparators.py --imma=../../../../imma/Kon-Tiki_1947.imma --var=prmsl
./get_comparators.py --imma=../../../../imma/Kon-Tiki_1947.imma --var=air.2m
./get_comparators.py --imma=../../../../imma/Kon-Tiki_1947.imma --var=air.sfc
./get_comparators.py --imma=../../../../imma/Kon-Tiki_1947.imma --var=uwnd.10m
./get_comparators.py --imma=../../../../imma/Kon-Tiki_1947.imma --var=vwnd.10m

./plot_pressure_comparison.py
./plot_AT_comparison.py
./plot_SST_comparison.py
./plot_W_comparison.py
./plot_D_comparison.py