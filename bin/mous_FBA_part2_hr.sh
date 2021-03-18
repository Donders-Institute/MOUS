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

subject=$1

# define some folder names and file names
output_folder=/project/3011020.09/processed/"$subject"/mri_dti/mrtrix
scriptdir=`dirname "$0"`

wm="$scriptdir"/mous_avg198_response_wm.txt
gm="$scriptdir"/mous_avg198_response_gm.txt
csf="$scriptdir"/mous_avg198_response_csf.txt

## increase the voxel resolution as per the suggestion in the MRTrix documentation
output_folder_hr="$output_folder"_hr
mkdir -p $output_folder_hr
mrresize "$output_folder"/data_reg.mif -vox 1.25 "$output_folder_hr"/data_reg_hr.mif
mrresize "$output_folder"/data_mask.nii.gz -vox 1.25 -interp nearest -datatype bit "$output_folder_hr"/data_mask_hr.nii.gz

# fod estimation
ss3t_csd_beta1 "$output_folder_hr"/data_reg_hr.mif $wm "$output_folder_hr"/wmfod.mif $gm "$output_folder_hr"/gm.mif $csf "$output_folder_hr"/csf.mif -mask "$output_folder_hr"/data_mask_hr.nii.gz -scratch /tmp/ -force -nthreads 8
mtnormalise "$output_folder_hr"/wmfod.mif "$output_folder_hr"/wmfod.mif "$output_folder_hr"/gm.mif "$output_folder_hr"/gm.mif "$output_folder_hr"/csf.mif "$output_folder_hr"/csf.mif -mask "$output_folder_hr"/data_mask_hr.nii.gz -force -nthreads 8

