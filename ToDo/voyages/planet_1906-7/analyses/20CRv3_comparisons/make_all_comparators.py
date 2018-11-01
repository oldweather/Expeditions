#!/usr/bin/env python

# Extract data from 20CRv3 along the route of a ship.

# Generates a set of jobs to be run in parallel on SPICE

import IMMA
o_source=IMMA.read('../../../../imma/Planet_1906-7.imma')

f=open("run.txt","w+")
for var in ('prmsl','air.2m','air.sfc'):
   for start in range(0,len(o_source),10):
      f.write("./get_comparators.py --imma=%s --var=%s --start=%d --end=%d\n" %
              ('../../../../imma/Planet_1906-7.imma',var,start,start+9))
f.close()
