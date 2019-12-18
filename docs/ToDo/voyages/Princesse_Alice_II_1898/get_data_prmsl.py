#!/usr/bin/env python

import IRData.twcr as twcr
import datetime

for month in (4,5,6,7,8):
    dtn=datetime.datetime(1947,month,1)
    twcr.fetch('prmsl',dtn,version='4.5.1')

