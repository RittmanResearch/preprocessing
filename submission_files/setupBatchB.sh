#! /bin/bash
cwd=`pwd`
for i in */*/* ; do
 cd $i
 cd preprocessing
 rm eBmask* _eBmask.nii FUNCTIONAL_reg_baseline* gms.1D FUNCTIONAL_sm.nii FUNCTIONAL_pppre.nii DATA_do_epi.nii FUNCTIONAL_csfmask.nii FUNCTIONAL_pppre.nii FUNCTIONAL_csf.1D FUNCTIONAL_pp* FUNCTIONAL_reg_baseline.1D FUNCTIONAL_mean.nii
 cd ../
 echo `pwd`
 ln -s /home/tr332/imageAnalysis/slurm_submitScriptB.hphi .
 sbatch slurm_submitScriptB.hphi
 cd $cwd
done
