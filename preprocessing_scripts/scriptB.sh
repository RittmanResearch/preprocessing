# this script runs the final part of the preprocessing. 
#
# The inputs are wavelet despiked functional image and a structural image coregistered to the functional image.
#
#

## set dummy display
Xvfb :88 & 
export DISPLAY=:88

##move in to directory
cd preprocessing
3dcalc -expr 'a' -a ./FUNCTIONAL_wds.nii.gz[5] -prefix eBmask.nii # this line takes only the 5th image of the functional data

# create binary mask - used in the final regression
3dcalc -a eBmask.nii -b eBmask.nii -expr 'a/b' -prefix eBmask_bin.nii 

# segment functional image
fast -t 2 -n 3 -H 0.1 -I 4 -l 20.0 -b -o eBmask eBmask.nii # use the 5th volume for segmentation

# obtain motion derivatives
1dcat motion_dm.1D motion_deriv.1D > FUNCTIONAL_reg_baseline_pre.1D

# find mean value in the representative slice
3dBrickStat -mask eBmask.nii -percentile 50 1 50  eBmask.nii > gms.1D
gms=`cat gms.1D`; gmsa=($gms); p50=${gmsa[1]}

# multiply by 1000 then divide by the mean value of the image
3dcalc -overwrite -a ./FUNCTIONAL_wds.nii.gz -expr 'a*1000' -prefix ./FUNCTIONAL_wds.nii.gz
3dcalc -overwrite -a ./FUNCTIONAL_wds.nii.gz -expr "a/$p50" -prefix ./FUNCTIONAL_wds.nii.gz

# take the mean of each voxel across the timeseries
3dTstat -prefix ./FUNCTIONAL_mean.nii ./FUNCTIONAL_wds.nii.gz

# add the mean values to the image
3dcalc -overwrite -a ./FUNCTIONAL_wds.nii.gz -b ./FUNCTIONAL_mean.nii -expr 'a+b' -prefix ./FUNCTIONAL_wds.nii.gz

# regress out movement parameters and bandpass - temporary file to identify CSF timeseries
3dTproject -ort FUNCTIONAL_do_al_reg_mat.aff12.1D -prefix ./FUNCTIONAL_pppre.nii -bandpass 0.01 99 -input ./FUNCTIONAL_wds.nii.gz

echo Downsampling anatomical and segmenting with FSL FAST...
# match structural to functional resolution and orientation 
3dresample -rmode Li -master eBmask.nii -inset DATA_do.nii -prefix DATA_do_epi.nii

# do regression on structure image
fast -t 1 -n 3 -H 0.1 -I 4 -l 20.0 -g -b -o DATA_do_epi DATA_do_epi.nii

# save CSF mask
3dcalc -a DATA_do_epi_seg_1.nii -b eBmask_pve_2.nii -expr 'notzero(b)*(equals((a+b),1)+equals((a+b),2))' -prefix FUNCTIONAL_csfmask.nii  

# save timeseries associated with CSF
3dcalc -overwrite -prefix FUNCTIONAL_csfmask.nii -a FUNCTIONAL_csfmask.nii -b eBmask.nii -expr 'a*b'
3dmaskave -quiet -mask FUNCTIONAL_csfmask.nii FUNCTIONAL_pppre.nii > FUNCTIONAL_csf.1D

# put motion, motion derivatives and CSF regressors in to a single line
1dcat motion_dm.1D motion_deriv.1D FUNCTIONAL_csf.1D > FUNCTIONAL_reg_baseline.1D

# apply regressors
3dTproject -ort FUNCTIONAL_reg_baseline.1D -prefix ./FUNCTIONAL_pp.nii -bandpass 0.010000 99.000000 -input ./FUNCTIONAL_wds.nii.gz

# mask output by the functional image
3dcalc -a ./FUNCTIONAL_pp.nii -b ./eBmask_bin.nii -expr 'a*b' -prefix ./FUNCTIONAL_ppm.nii

# mask by the skull stripped structural image
3dSkullStrip -input DATA_do_epi.nii -prefix DATA_do_epi_ss.nii -push_to_edge
3dcalc -a ./DATA_do_epi_ss.nii -b ./DATA_do_epi_ss.nii -expr 'a/b' -prefix ./DATA_do_epi_ss_mask.nii
3dcalc -a ./FUNCTIONAL_ppm.nii -b ./DATA_do_epi_ss_mask.nii -expr 'a*b' -prefix ./FUNCTIONAL_ppmm.nii

## copy output to home directory
cp FUNCTIONAL_ppmm.nii ../

# Removing all the temporary files
rm -f ./__tt_FUNCTIONAL_do1D 
rm -f ./__tt_DATA_do*

# return to home directory
cd ../

# close dummy X server
unset DISPLAY
killall Xvfb

