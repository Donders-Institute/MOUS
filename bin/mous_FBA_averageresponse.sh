#! /bin/sh

# This shell script intends to perform Guilherme's MRTrix group analysis pipeline on the MOUS tractography data.
# In addition, it aims to prepare the data such, that TractSeg can operate on it. 
#
# Software requirements:
#  - MRTrix3Tissue -> contains code to estimate 3-tissue constrained FODs on single shell diffusion data
#  - MRTrix3 -> mrresize is not present in MRTrix3Tissue. Also, for now MRTrix3 and MRTrix3Tissue differ in the name of options -tempdir vs. -scratch (be warned)
#  - ANTS for bias correction of diffusion data (using the didi processed data off the shelf anecdodally did not work well
#  - FSL
#  - TractSeg
#
# The steps are:
#  1. Register the diffusion data to the FA template in TractSeg (needed for smooth Tractseg)
#  2. Register the anatomical data to the registered diffusion data
#  3. 5tt segmentation of anatomical data
#  4. Bias correction of diffusion data (anecdotally otherwise dwi2mask fails, which seems suggestive of inhomogeneous data quality after didi)
#  5. Response function estimation
#  6. FOD estimation
#  7. 

DATADIR=/project/3011020.09/processed

# Compute average response functions
N=`ls "$DATADIR"/*/mri_dti/mrtrix/ms_wm.txt|wc -w`

average_response "$DATADIR"/*/mri_dti/mrtrix/ms_wm.txt  mous_avg"$N"_response_wm.txt
average_response "$DATADIR"/*/mri_dti/mrtrix/ms_gm.txt  mous_avg"$N"_response_gm.txt
average_response "$DATADIR"/*/mri_dti/mrtrix/ms_csf.txt mous_avg"$N"_response_csf.txt

