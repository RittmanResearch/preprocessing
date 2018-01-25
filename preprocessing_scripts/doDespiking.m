pd = pwd
cd /home/tr332/BrainWavelet_v1.1_fMRI_Linux_Windows/BrainWavelet
setup
cd(pd)
WaveletDespike('FUNCTIONAL_do_al.nii', 'FUNCTIONAL', 'LimitRAM', 4,'threshold', 10)
quit()
