#! /bin/bash
cwd=`pwd`
for i in */*/* ; do
 cd $i
 echo `pwd`
 sbatch /home/preprocessing/slurm_files/slurm_submitScriptB.hphi
 cd $cwd
done
