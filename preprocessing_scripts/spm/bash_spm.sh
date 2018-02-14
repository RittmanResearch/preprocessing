#!/bin/bash

# set up file inputs
inflowfield=u_rc1DATA_do_ControlPSPTemplate.nii
inepiimage=FUNCTIONAL_pp.nii
instructural=DATA_do.nii

template='/home/tr332/scratch/functional/ControlPSPTemplate_6.nii'

#Rewrite 4D images so they have a standard header
nvols=`fslnvols $inepiimage`
echo Number of volumes are $nvols
echo In EPI is ${inepiimage}

inepiimage_clean=${inepiimage%.nii}_cl.nii
echo In EPI $inepiimage_clean

fslroi ${inepiimage} ${inepiimage_clean} 0 $nvols

# transform images in to standard space
stdepiimage=FUNCTIONAL_pp_std.nii
fslreorient2std $inepiimage_clean $stdepiimage

stdstructural=DATA_do_std.nii
fslreorient2std $instructural $stdstructural

#Run matlab
spmpath=/applications/spm/spm12_6906/
matlab -nodesktop -nodisplay -nojvm<<EOF

try
  spm quit;
  clear all;
  
  spm_rmpath;
end

if isunix
   
    addpath('$spmpath');
    addpath(genpath('$spmpath'));
    addpath /home/tr332/preprocessing/preprocessing_scripts/spm/;
else
    addpath c:\data\spm\spm12b\;
end

clear global;
path
%spm;

spm_normalise_mni_epis('$template','$inflowfield','$stdepiimage','$stdstructural');
exit
EOF

echo 'Finished batch' 
