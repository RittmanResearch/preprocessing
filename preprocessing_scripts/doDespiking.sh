#!/bin/bash
cd preprocessing
ln -s ~/preprocessing/preprocessing_scripts/doDespiking.m .
matlab -nosplash -nodesktop -r "doDespiking"
cd ../
