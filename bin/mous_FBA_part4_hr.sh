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

# Run the template building script
population_template $group_folder_dwi/fod_input $group_folder_dwi/wmfod_template.mif -mask_dir $group_folder_dwi/mask_input -voxel_size 1.25 -tempdir $group_folder_dwi/tempdir -nocleanup -nthreads 8 -force > $group_folder_dwi/population_template.log 2>&1
#population_template $group_folder_dwi/fod_input $group_folder_dwi/wmfod_template.mif -mask_dir $group_folder_dwi/mask_input -voxel_size 2.2 -tempdir $group_folder_dwi/tempdir -continue $group_folder_dwi/tempdir warps_13/V1116.mif -nocleanup -force > $group_folder_dwi/population_template.log 2>&1
