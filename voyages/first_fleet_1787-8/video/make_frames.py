#!/usr/bin/env python

# Make all the individual frames for a movie
#  run the jobs on SPICE.

import os
import subprocess
import datetime

start_day = datetime.datetime(1787, 5, 14, 12)
end_day = datetime.datetime(1788, 2, 18, 23)

# Function to check if the job is already done for this timepoint
def is_done(year, month, day, hour):
    op_file_name = ("%s/images/FirstFleet/" + "%04d%02d%02d%02d.png") % (
        os.getenv("SCRATCH"),
        year,
        month,
        day,
        int(hour),
    )
    if os.path.isfile(op_file_name):
        return True
    return False


f = open("run.txt", "w+")
current_day = start_day
while current_day <= end_day:
    if is_done(current_day.year, current_day.month, current_day.day, current_day.hour):
        current_day = current_day + datetime.timedelta(hours=1)
        continue
    cmd = ("./FFFrame.py --year=%d --month=%d" + " --day=%d --hour=%f\n") % (
        current_day.year,
        current_day.month,
        current_day.day,
        current_day.hour,
    )
    f.write(cmd)
    current_day = current_day + datetime.timedelta(hours=24)
