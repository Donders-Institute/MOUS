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

# These lists contain the matching IDs of the subjects known in BIG, and MOUS respectively
subjectsB=`cat /project/3013020.01/niftibox/sMRI/FreeSurfer_v53/tracula/bin/scripts_mous/subjectlist_BIG_run.txt`
subjectsM=`cat /project/3013020.01/niftibox/sMRI/FreeSurfer_v53/tracula/bin/scripts_mous/subjectlist_MOUS.txt`


group_folder_dwi=/project/3011020.09/processed/mrtrix_group_hr
mkdir -p $group_folder_dwi
mkdir -p $group_folder_dwi/fod_input
mkdir -p $group_folder_dwi/mask_input

set -- $subjectsB
for subject in $subjectsM;do
runnr="${1: -1}"
sname="${1:0:7}"
echo $subject $sname $runnr

# define some folder names and file names
output_folder=/project/3011020.09/processed/"$subject"/mri_dti/mrtrix

# Symbolic link all FOD images and masks into a single input folder #
ln -sr $output_folder/wmfod.mif $group_folder_dwi/fod_input/$subject.mif 
ln -sr $output_folder/data_mask.nii.gz $group_folder_dwi/mask_input/$subject.nii.gz

shift
done

# remove the as of yet bad subjects (i.e. the ones that have not been processed properly by didi
cd $group_folder_dwi/fod_input
rm V1058.mif
rm V1090.mif
rm V1117.mif
rm A2009.mif
rm A2068.mif
rm A2078.mif

cd $group_folder_dwi/mask_input
rm V1058.nii.gz
rm V1090.nii.gz
rm V1117.nii.gz
rm A2009.nii.gz
rm A2068.nii.gz
rm A2078.nii.gz

