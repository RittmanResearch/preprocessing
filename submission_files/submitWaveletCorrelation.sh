wd=`pwd`
for i in */*/*/preprocessing ; do
 cd $i
 rm slurm_waveletCorrelation.hphi
 sbatch ~/preprocessing/slurm_files/slurm_waveletCorrelation.hphi
 cd $wd
done

