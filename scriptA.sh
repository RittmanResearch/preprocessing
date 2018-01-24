# this script runs the first part of the preprocessing of resting state functional imaging. The inputs
# are: 1. a raw fMRI dataset, 2. a structural (MPRAGE) image.
#
# the steps include:
# - deobliquing images
# - aligning the functional to the structural image
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

## do not run the following lines, they were used only to create the script below
## coregister functional to structural
## includes slice timing correction, motion alignment
# align_epi_anat.py -anat DATA_do+orig -epi FUNCTIONAL_do+orig -epi_base 0 -epi2anat -deoblique -volreg on -tshift on -save_all -AddEdge
# align_epi_anat.py -anat ./DATA_do+orig -epi ./FUNCTIONAL_do+orig -epi_base 0 -tshift on -volreg on -giant_move -ex_mode dry_run -epi2anat -AddEdge -save_all
# ./align.sh

#++ align_epi_anat version: 1.54
#++ turning on volume registration
#Would be running (command trimmed):
#  3dAttribute DELTA ./FUNCTIONAL_do+orig
#Would be running (command trimmed):
#  3dAttribute DELTA ./FUNCTIONAL_do+orig
#Would be running (command trimmed):
#  3dAttribute DELTA ./DATA_do+orig
#++ Multi-cost is lpc
#Would be running (command trimmed):
  3dcopy ./DATA_do.nii ./__tt_DATA_do+orig
  #cp ./DATA_do.nii ./__tt_DATA_do+orig
#++ Removing skull from anat data
#Would be running (command trimmed):
  3dSkullStrip -orig_vol -input ./__tt_DATA_do+orig -prefix ./__tt_DATA_do_ns+orig
#Would be running (command trimmed):
#  3dinfo ./__tt_DATA_do_ns+orig | \grep 'Data Axes Tilt:'|\grep 'Oblique'
#Would be running (command trimmed):
#  3dAttribute DELTA ./__tt_DATA_do_ns+orig
#++ Matching obliquity of anat to epi
#Would be running (command trimmed):
  3dWarp -verb -card2oblique ./FUNCTIONAL_do+orig -prefix ./__tt_DATA_do_ns_ob+orig -newgrid 1.25 ./__tt_DATA_do_ns+orig | \grep -A 4 '# mat44 Obliquity Transformation ::' > ./__tt_DATA_do_ns_obla2e_mat.1D
#Would be running (command trimmed):
#  3dAttribute TAXIS_OFFSETS ./FUNCTIONAL_do+orig
#++ Correcting for slice timing
#Would be running (command trimmed):
  3dTshift -prefix ./FUNCTIONAL_do_tsh+orig -cubic ./FUNCTIONAL_do+orig
#++ Volume registration for epi data
#Would be running (command trimmed):
  3dvolreg -1Dfile ./FUNCTIONAL_do_tsh_vr_motion.1D -1Dmatrix_save ./FUNCTIONAL_do_tsh_vr_mat.aff12.1D -prefix ./FUNCTIONAL_do_tsh_vr+orig -base 0 -cubic ./FUNCTIONAL_do_tsh+orig
#++ Creating representative epi sub-brick
#Would be running (command trimmed):
  3dbucket -prefix ./FUNCTIONAL_do_tsh_vr_ts+orig ./FUNCTIONAL_do_tsh_vr+orig'[0]'
#++ removing skull or area outside brain
#Would be running (command trimmed):
  3dSkullStrip -orig_vol -input ./FUNCTIONAL_do_tsh_vr_ts+orig -prefix ./FUNCTIONAL_do_tsh_vr_ts_ns+orig
#++ Computing weight mask
#Would be running (command trimmed):
  3dBrickStat -automask -percentile 90.000000 1 90.000000 ./FUNCTIONAL_do_tsh_vr_ts_ns+orig
#++ Would be applying threshold for real run here
#Would be running (command trimmed):
  3dcalc -datum float -prefix ./FUNCTIONAL_do_tsh_vr_ts_ns_wt+orig -a ./FUNCTIONAL_do_tsh_vr_ts_ns+orig -expr 'min(1,(a/-999.000000))'
#++ Aligning anat data to epi data
#Would be running (command trimmed):
  3dAllineate -lpc -wtprefix ./__tt_DATA_do_ns_ob_al_wtal -weight ./FUNCTIONAL_do_tsh_vr_ts_ns_wt+orig -source ./__tt_DATA_do_ns_ob+orig -prefix ./__tt_DATA_do_ns_ob_temp_al+orig -base ./FUNCTIONAL_do_tsh_vr_ts_ns+orig -cmass -1Dmatrix_save ./DATA_do_al_e2a_only_mat.aff12.1D -master BASE -mast_dxyz 1.25 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -twobest 11 -twopass -VERB -maxrot 45 -maxshf 40 -fineblur 1 -source_automask+2 
#++  Aligning /lustre/scratch/wbic-beta/tr332/sandBox/preprocessing/FUNCTIONAL_do_tsh+orig to anat
#++ Inverting anat to epi matrix
#Would be running (command trimmed):
  cat_matvec -ONELINE ./__tt_DATA_do_ns_obla2e_mat.1D ./DATA_do_al_e2a_only_mat.aff12.1D -I > ./FUNCTIONAL_do_al_mat.aff12.1D
#++ Concatenating volreg and epi to anat transformations
#Would be running (command trimmed):
  cat_matvec -ONELINE ./__tt_DATA_do_ns_obla2e_mat.1D ./DATA_do_al_e2a_only_mat.aff12.1D -I ./FUNCTIONAL_do_tsh_vr_mat.aff12.1D > ./FUNCTIONAL_do_al_reg_mat.aff12.1D
#++ Applying transformation of epi to anat
#Would be running (command trimmed):
  3dAllineate -base ./DATA_do.nii -1Dmatrix_apply ./FUNCTIONAL_do_al_reg_mat.aff12.1D -prefix ./FUNCTIONAL_do_al+orig -input ./FUNCTIONAL_do_tsh+orig -master BASE -mast_dxyz 1.25 -weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp aff -source_automask+4 -twobest 11 -twopass -VERB -maxrot 45 -maxshf 40 -fineblur 1 -source_automask+2
#Would be running (command trimmed):
  3drefit -deoblique ./FUNCTIONAL_do_al+orig
#Would be running:
  cd ./; \rm -f AddEdge/*
#++ resampling epi to match anat data
#Would be running (command trimmed):
  3dresample -master ./__tt_DATA_do_ns_ob+orig -prefix ./__tt_FUNCTIONAL_do_rs_in+orig -inset ./FUNCTIONAL_do_tsh_vr_ts_ns+orig'' -rmode Cu
#++ Applying transformation for epi to anat for @AddEdge
#Would be running (command trimmed):
  3dAllineate -base ./DATA_do.nii -1Dmatrix_apply './FUNCTIONAL_do_al_reg_mat.aff12.1D{0}' -prefix ./__tt_FUNCTIONAL_do_addedge+orig -input ./__tt_FUNCTIONAL_do_rs_in+orig -master BASE
#Would be running:
  mkdir ./AddEdge
#Would be running (command trimmed):
  3dcopy -overwrite ./__tt_DATA_do_ns_ob+orig ./AddEdge/DATA_do_ns
#Would be running (command trimmed):
  3dcopy -overwrite ./__tt_FUNCTIONAL_do_rs_in+orig ./AddEdge/FUNCTIONAL_do_ns
#Would be running (command trimmed):
  3dcopy -overwrite ./__tt_FUNCTIONAL_do_addedge+orig ./AddEdge/FUNCTIONAL_do_al
#Would be running (command trimmed):
#  cd ./AddEdge; @AddEdge -no_deoblique DATA_do_ns+orig FUNCTIONAL_do_ns+orig FUNCTIONAL_do_al+orig; cd - 
#++ Creating final output: skullstripped anat data
#Would be running (command trimmed):
  3dcopy ./__tt_DATA_do_ns+orig DATA_do_ns
#++ Creating final output: weighting data
#Would be running (command trimmed):
  3dcopy ./__tt_DATA_do_ns_ob_al_wtal+orig FUNCTIONAL_do_wt_in_3dAl_al
#++ Creating final output: epi representative data as used by 3dAllineate
#Would be running (command trimmed):
  3dcopy ./FUNCTIONAL_do_tsh_vr_ts_ns+orig FUNCTIONAL_do_epi_in_3dAl_al
#++ Creating final output: anat data as used by 3dAllineate
#Would be running (command trimmed):
  3dcopy ./DATA_do.nii DATA_do_anat_in_3dAl_al
#++ Creating final output: epi data aligned to anat
# copy is not necessary
#++ Saving history
#Would be running (command trimmed):
  3dNotes -h "align_epi_anat.py -anat ./DATA_do.nii -epi ./FUNCTIONAL_do+orig \
 -epi_base 0 -tshift on -volreg on -giant_move -ex_mode dry_run -epi2anat \
 -AddEdge -save_all" \
 ./FUNCTIONAL_do_al+orig

# # Finished alignment successfully
# To view edges produced by @AddEdge, type:
# cd AddEdge
# @AddEdge

## end of the align_align_epi_anat.py function

## segment functional dataset
1d_tool.py -demean -infile FUNCTIONAL_do_al_reg_mat.aff12.1D -write motion_dm.1D
1d_tool.py -demean -derivative -infile FUNCTIONAL_do_al_reg_mat.aff12.1D -write motion_deriv.1D

## return to home directory
cd ../

## close dummy X server
unset DISPLAY
killall Xvfb

