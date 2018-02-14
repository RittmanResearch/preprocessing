wd=`pwd`
for i in */*/*/timeseries ; do
 echo $i
 cd $i
 sbatch ~/preprocessing/slurm_files/slurm_waveletCorrelation.hphi
 cd $wd
done

