cwd=`pwd`
for i in ~/scratch/functional/*/*/*/preprocessing ; do
 echo $i
 cd $i
 sbatch ~/preprocessing/slurm_files/ICA_prepare_images.hphi
 cd $cwd
done
