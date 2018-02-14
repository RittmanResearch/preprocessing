#!/bin/bash
cwd=`pwd`
for i in */*/*; do
 echo $i
 cd $i
 sbatch /home/tr332/preprocessing/slurm_files/slurm_submitTSScript.hphi
 cd $cwd
done 
