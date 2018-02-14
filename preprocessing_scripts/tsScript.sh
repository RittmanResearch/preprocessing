#!/bin/bash
cd preprocessing
func=FUNCTIONAL_ppmm_std.nii # functional file warped to MNI space 
struc=DATA_do_std.nii # structural file warped to study specific template
tsScript=/home/tr332/preprocessing/preprocessing_scripts/tsExtractorScript.py
parcelDir=/home/tr332/fmri_spt_wav/templates/parcel_temps
# export FSLOUTPUTTYPE=NIFTI_GZ ## should be unnecessary if this is set in the bashrc script (doesn't seem to work anyway)

# change file types to gunzipped nifti files
fslchfiletype NIFTI_GZ $func
mv $func ${func/.nii/.nii.old}
fslchfiletype NIFTI_GZ $struc
rm $struc # remove duplicate scans

# ensure scans are aligned to MNI space
echo downsampling functional image
flirt -in DATA_do_std.nii.gz -ref ${FSLDIR}/data/standard/MNI152_T1_2mm.nii.gz -omat toMNI.mat
flirt -in FUNCTIONAL_ppmm_std.nii.gz -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain.nii.gz -applyxfm -init toMNI.mat -out FUNCTIONAL_ppmm_std_2mm.nii.gz

# redefine functional image
func=FUNCTIONAL_ppmm_std_2mm.nii.gz

echo "Creating mean functional image"
fslmaths $func -Tmean ${func/.nii.gz/_mean.nii.gz}

echo "Creating functional mask"
mask=${func/.nii.gz/_mask.nii.gz}
fslmaths ${func/.nii.gz/_mean.nii.gz} -mul ${func/.nii.gz/_mean.nii.gz} -bin $mask

echo "Removing existing parcellation templates"
rm parcel_*

# iterate through the parcellation schemes
for x in 100 200 300 400 500 ; do
 echo $x
 parcel=parcel_${x}.nii
 echo "Getting parcellation template"
 cp ${parcelDir}/${parcel} . # copy parcel locally
 fslchfiletype NIFTI_GZ $parcel # convert parcel to gunzipped file
 parcel=${parcel}.gz

 # create output file and overwrite any existing file
 outFile=FUNCTIONAL_ppmm_std_2mm_${x}_ts.txt
 rm $outFile 
 touch $outFile

 # mask parcel file by input mask
 parcelm=parcel_${x}m.nii.gz
 fslmaths $parcel -mas $mask $parcelm
 
 rm ind*
 for i in $(seq 1 $x) ; do
  ind=ind${x}.nii.gz
  fslmaths $parcelm -sub $i $ind
  # create a mask of 1's in the area of interest
  fslmaths $ind -mul $ind -bin -mul -1 -add 1 $ind
  
  # get number of voxels of parcellated brain
  nVox=`fslstats $ind -V`
  set -- $nVox
  nVox=$1
 
  if [ $nVox -gt 10 ] ; then 
   line=`fslmeants -i $func -m $ind --transpose`
   echo $line >> $outFile

  else
   line=`fslmeants -i $func -m $ind --transpose`
   len=`wc -w <<< $line`
   
   echo "Not enough voxels"
   echo `yes "NA" | head -n $len` >> $outFile

  fi


  rm $ind
 done 
done
# tidy up
rm parcel_*
rm ind*
rm tempScript.sh

cd ../
mkdir timeseries
mv preprocessing/*ts.txt timeseries
