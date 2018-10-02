#!/usr/bin/env python

# Make all the individual frames for a movie
#  run the jobs on SPICE.

import os
import subprocess
import datetime

max_jobs_in_queue=500
# Where to put the output files
opdir="%s/slurm_output" % os.getenv('SCRATCH')
if not os.path.isdir(opdir):
    os.makedirs(opdir)

start_day=datetime.datetime(1947, 4, 28,  0)
end_day  =datetime.datetime(1947, 8,  7, 23)

# Function to check if the job is already done for this timepoint
def is_done(year,month,day,hour):
    op_file_name=("%s/images/Kon-Tiki/" +
                  "V3vobs_Kon-Tiki_%04d%02d%02d%02d%02d.png") % (
                            os.getenv('SCRATCH'),
                            year,month,day,int(hour),
                                        int(hour%1*60))
    if os.path.isfile(op_file_name):
        return True
    return False

current_day=start_day
while current_day<=end_day:
    queued_jobs=subprocess.check_output('squeue --user hadpb',
                                         shell=True).count('\n')
    max_new_jobs=max_jobs_in_queue-queued_jobs
    while max_new_jobs>0 and current_day<=end_day:
        f=open("multirun.slm","w+")
        f.write('#!/bin/ksh -l\n')
        f.write('#SBATCH --output=%s/Kon-Tiki_frame_%04d%02d%02d%02d.out\n' %
                   (opdir,
                    current_day.year,current_day.month,
                    current_day.day,current_day.hour))
        f.write('#SBATCH --qos=normal\n')
        f.write('#SBATCH --ntasks=4\n')
        f.write('#SBATCH --ntasks-per-core=1\n')
        f.write('#SBATCH --mem=40000\n')
        f.write('#SBATCH --time=10\n')
        count=0
        for fraction in (0,1,2,3):
            if is_done(current_day.year,current_day.month,
                           current_day.day,current_day.hour+fraction):
                continue
            cmd=("./KT_V3vobs.py --year=%d --month=%d" +
                " --day=%d --hour=%f &\n") % (
                   current_day.year,current_day.month,
                   current_day.day,current_day.hour+fraction)
            f.write(cmd)
            count=count+1
        f.write('wait\n')
        f.close()
        current_day=current_day+datetime.timedelta(hours=4)
        if count>0:
            max_new_jobs=max_new_jobs-1
            rc=subprocess.call('sbatch multirun.slm',shell=True)
        os.unlink('multirun.slm')
