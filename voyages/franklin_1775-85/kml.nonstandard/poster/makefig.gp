# Gnuplot script to make figure for John B's Franklin poster

set term postscript color eps 18
set output 'SST_scatter.eps'
set xlabel 'Modern day SST'
set xrange [10:28]
set ylabel 'Franklin measurements'
set yrange [10:28]
set key left
plot x notitle w l lt -1,\
    '../comparison_with_climatology/comparison_with_hadisst_1775' using 3:2 \
       title '1775' w p pt 4 ps 2 lt 3 lw 3,\
    '../comparison_with_climatology/comparison_with_hadisst_1776' using 3:2 \
       title '1776' w p pt 2 ps 2 lt 3 lw 3,\
    '../comparison_with_climatology/comparison_with_hadisst' using 3:2 \
       title '1785' w p pt 1 ps 2 lt 3 lw 3,\
    '-' title 'August 21 1785' w p pt 1 ps 2 lt 1 lw 3
25.5 23.3
e
!epstopdf SST_scatter.eps
    
