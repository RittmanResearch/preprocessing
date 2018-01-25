cwd=`pwd`
for i in */*/* ; do
 cd $i
 echo `pwd`
 ln -s /home/tr332/preprocessing/preprocessing_scripts/doDespiking.m preprocessing/ 
 sbatch ~/preprocessing/slurm_files/slurm_submit_despike.hphi
 cd $cwd
done
