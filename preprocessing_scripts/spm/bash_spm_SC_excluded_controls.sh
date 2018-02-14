#!/bin/bash
#
#PBS -N Matlab
#PBS -m be 
#PBS -k oe

#diagnosis=Control #$1 
#wbic=$1  #$2
#condition=placebo  #$3
#echo 'diagnosis is: '${diagnosis}
#echo 'WBIC number is: '${wbic}
#echo 'condition is: '${condition}

#if you use this then when you run the script in the command line type: "bash bash_spm.sh 10075" that way the wbic variable will be the wbic number you type in. This way you have to run it individually for every person. 
#Start matlab and run spm job to warp epi images
mainDir='/scratch/rb729/controls_originally_excluded_SeedCorrSM8_adjust/'
cd $mainDir

#for d in PD; do #{Control,PD}; do
#	cd $d
#	echo $d
	
		for s in *; do #* ; do
			cd $s
			echo $s

#		for cond in * ; do
#			echo $cond
#			cd $cond

			template='/scratch/rb729/SPM_SeedCorrSM8_adjust/Control/10075/placebo/Template_deob_6.nii' #change this to the new template once you have it
			inflowfield='/scratch/rb729/controls_originally_excluded_SeedCorrSM8_adjust/'${s}'/u_rc1'${s}'_structural_reordered_deob_Template_deob.nii'

			#For the first run through the data for graph analysis our input EPI files were the output files from ameera's pipeline, these were the functional_reordered_pp.nii files. However these files are mean centered and have other attributes which SPM doesn't like so for the seed correlation we're running in SPM we have to take EPI files from an earlier stage in the pre-processing. We're going to use (at least try) the functional_reordered_sm_before.nii files
			#inepiimage='/scratch/rb729/PDStudy/'${diagnosis}'/'${wbic}'/'${condition}'/'${wbic}'_functional_reordered_pp.nii'
			inepiimage='/scratch/rb729/controls_originally_excluded_SeedCorrSM8_adjust/'${s}'/'${s}'_functional_reordered_sm_wds.nii.gz'


			instructural='/scratch/rb729/controls_originally_excluded_SeedCorrSM8_adjust/'${s}'/'${s}'_structural_reordered_deob.nii'

			#Rewrite 4D images so they have a standard header
			nvols=`fslnvols $inepiimage`
			echo Number of volumes are $nvols
			echo In EPI is ${inepiimage}

			inepiimage_clean=${inepiimage%.nii}_cl.nii
			echo In EPI $inepiimage_clean

			fslroi ${inepiimage} ${inepiimage_clean} 0 $nvols

			gunzip ${inepiimage_clean} 

			#Run matlab
			spmpath=/app/spm/spm12b_6033/;
			/app0/x86_64/matlabR2007b/bin/matlab -nodesktop -nodisplay -nojvm << EOF

			try
			  spm quit;
			  clear all;
			  
			  spm_rmpath;
			end

			if isunix
			   
			   %addpath /home/spj24/spm/spm12b/;
			    %addpath /app0/x86_64/spm12b_6033/;
			    addpath('$spmpath');
			    %addpath /app/spm/spm12b_6033/toolbox/DARTEL/;
			    addpath(genpath('$spmpath'));
			   addpath /home/rb729/matlab/spm/;
			else
			    addpath c:\data\spm\spm12b\;
			end

			clear global;
			path
			%spm;

			%spm('defaults','pet');
			%spm_jobman('initcfg');

			%disp('$inflowfield')
			%disp('$inmeanimage')
			%cd /scratch/spj24/robin/jobs/
		
			spm_normalise_mni_epis('$template','$inflowfield','$inepiimage_clean','$instructural');
			
			exit
EOF

			echo 'Finished batch for '$s
			
			cd ../
			
		done
#		cd ../
#		
#	done
#	cd ${mainDir}
#done		
