#! /bin/bash
cwd=`pwd`
for i in */*/* ; do
 cd $i
 echo `pwd`
 sbatch /home/tr332/preprocessing/slurm_files/slurm_submitScriptA.hphi
 cd $cwd
done
