#!/bin/bash
cwd=`pwd`
for i in */*/*/preprocessing ; do
 cd $i
 ln -s /home/tr332/imageAnalysis/slurm_submitTSScript.hphi .
 sbatch slurm_submitTSScript.hphi
 cd $cwd
done 
