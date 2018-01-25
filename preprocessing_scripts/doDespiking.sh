#!/bin/bash
cd preprocessing
ln -s ~/preprocessing/preprocessing_scripts/doDespiking.m .
3dAFNItoNIFTI FUNCTIONAL_do_al+tlrc
matlab -nosplash -nodesktop -r "doDespiking"
cd ../
