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

group_folder_dwi=/project/3011020.09/processed/mrtrix_group_hr

# Perform whole-brain fibre tractography on the FOD template
tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 $group_folder_dwi/wmfod_template.mif -seed_image $group_folder_dwi/template_mask.mif -mask $group_folder_dwi/template_mask.mif -select 20000000 -cutoff 0.06 $group_folder_dwi/tracks_20_million.tck -force -nthreads 8

#Reduce biases in tractogram densities
tcksift $group_folder_dwi/tracks_20_million.tck $group_folder_dwi/wmfod_template.mif $group_folder_dwi/tracks_2_million_sift.tck -term_number 2000000 -force -nthreads 8
