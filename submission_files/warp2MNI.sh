#!/bin/bash
cwd=`pwd`
for i in */*/*/preprocessing ; do
 cd $i
 echo `pwd`
 sbatch /home/tr332/preprocessing/slurm_files/slurm_spmNormalise.hphi
 cd $cwd
done
