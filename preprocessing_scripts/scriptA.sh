# this script runs the first part of the preprocessing of resting state functional imaging. The inputs
# are: 1. a raw fMRI dataset, 2. a structural (MPRAGE) image.
#
# the steps include:
# - deobliquing images
# - skull stripping 
# - slice time correction
# - aligning the functional to structural image
#
# this script relies on commands from the align_epi_anat.py function, which were altered because the
# native script mislabelled scans with +tlrc rather than +orig meaning that parts of the script did not
# run.
#
# the final part of the script performs segmentation of the functional dataset to derive motion parameters.
#
#

## set dummy display
Xvfb :88 & 
export DISPLAY=:88

###make directory
mkdir preprocessing
cp *Resting_State*/FUNCTIONAL_????.nii preprocessing/FUNCTIONAL.nii
cp *MPRAGE*/DATA_????.nii preprocessing/DATA.nii
cd preprocessing

## deoblique
3dWarp -prefix DATA_do.nii -deoblique DATA.nii
3dWarp -prefix FUNCTIONAL_do+orig -deoblique FUNCTIONAL.nii
3drefit -deoblique -TR 2 FUNCTIONAL_do+orig

# start of align_epi_anat script
#++ align_epi_anat version: 1.54

#++ Multi-cost is lpc
3dcopy ./DATA_do.nii ./__tt_DATA_do+orig

#++ Removing skull from anat data
3dSkullStrip -orig_vol -input ./__tt_DATA_do+orig -prefix ./__tt_DATA_do_ns+orig

#++ Matching obliquity of anat to epi
3dWarp -verb -card2oblique ./FUNCTIONAL_do+orig -prefix ./__tt_DATA_do_ns_ob+orig -newgrid 1.25 ./__tt_DATA_do_ns+orig | \grep -A 4 '# mat44 Obliquity Transformation ::' > ./__tt_DATA_do_ns_obla2e_mat.1D

#++ Correcting for slice timing
3dTshift -prefix ./FUNCTIONAL_do_tsh+orig -cubic ./FUNCTIONAL_do+orig

#++ Volume registration for epi data
3dvolreg -1Dfile ./FUNCTIONAL_do_tsh_vr_motion.1D -1Dmatrix_save ./FUNCTIONAL_do_tsh_vr_mat.aff12.1D -prefix ./FUNCTIONAL_do_tsh_vr+orig -base 0 -cubic ./FUNCTIONAL_do_tsh+orig

#++ Creating representative epi sub-brick
3dbucket -prefix ./FUNCTIONAL_do_tsh_vr_ts+orig ./FUNCTIONAL_do_tsh_vr+orig'[0]'

#++ removing skull or area outside brain
3dSkullStrip -orig_vol -input ./FUNCTIONAL_do_tsh_vr_ts+orig -prefix ./FUNCTIONAL_do_tsh_vr_ts_ns+orig

#++ Computing weight mask
3dBrickStat -automask -percentile 90.000000 1 90.000000 ./FUNCTIONAL_do_tsh_vr_ts_ns+orig

#++ Applying threshold 
3dcalc -datum float -prefix ./FUNCTIONAL_do_tsh_vr_ts_ns_wt+orig -a ./FUNCTIONAL_do_tsh_vr_ts_ns+orig -expr 'min(1,(a/-999.000000))'

#++ Aligning anat data to epi data
3dAllineate -lpc -wtprefix ./__tt_DATA_do_ns_ob_al_wtal -weight ./FUNCTIONAL_do_tsh_vr_ts_ns_wt+orig -source ./__tt_DATA_do_ns_ob+orig -prefix ./__tt_DATA_do_ns_ob_temp_al+orig -base ./FUNCTIONAL_do_tsh_vr_ts_ns+orig -cmass -1Dmatrix_save ./DATA_do_al_e2a_only_mat.aff12.1D -master BASE -mast_dxyz 1.25 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -twobest 11 -twopass -VERB -maxrot 45 -maxshf 40 -fineblur 1 -source_automask+2 

#++  Aligning /lustre/scratch/wbic-beta/tr332/sandBox/preprocessing/FUNCTIONAL_do_tsh+orig to anat
#++ Inverting anat to epi matrix
cat_matvec -ONELINE ./__tt_DATA_do_ns_obla2e_mat.1D ./DATA_do_al_e2a_only_mat.aff12.1D -I > ./FUNCTIONAL_do_al_mat.aff12.1D

#++ Concatenating volreg and epi to anat transformations
cat_matvec -ONELINE ./__tt_DATA_do_ns_obla2e_mat.1D ./DATA_do_al_e2a_only_mat.aff12.1D -I ./FUNCTIONAL_do_tsh_vr_mat.aff12.1D > ./FUNCTIONAL_do_al_reg_mat.aff12.1D

#++ Applying transformation of epi to anat
3dAllineate -base ./DATA_do.nii -1Dmatrix_apply ./FUNCTIONAL_do_al_reg_mat.aff12.1D -prefix ./FUNCTIONAL_do_al -input ./FUNCTIONAL_do_tsh+orig -master BASE -mast_dxyz 1.25 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -twobest 11 -twopass -VERB -maxrot 45 -maxshf 40 -fineblur 1 -source_automask+2
3drefit -deoblique ./FUNCTIONAL_do_al+tlrc

## end of the align_align_epi_anat.py function

## segment functional dataset
1d_tool.py -demean -infile FUNCTIONAL_do_al_reg_mat.aff12.1D -write motion_dm.1D
1d_tool.py -demean -derivative -infile FUNCTIONAL_do_al_reg_mat.aff12.1D -write motion_deriv.1D

## return to home directory
cd ../

## close dummy X server
unset DISPLAY
killall Xvfb

