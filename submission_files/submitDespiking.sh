cwd=`pwd`
for i in */*/* ; do
 cd $i
 echo `pwd`
 sbatch ~/preprocessing/slurm_files/slurm_submit_despike.hphi
 cd $cwd
done
