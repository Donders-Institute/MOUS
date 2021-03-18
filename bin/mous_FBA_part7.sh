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

subject=$1
output_folder=/project/3011020.09/processed/"$subject"/mri_dti/mrtrix
group_folder_dwi=/project/3011020.09/processed/mrtrix_group

# Warp FOD images to template space ## 
mrtransform $output_folder/wmfod_norm.mif -warp $output_folder/subject2template_warp.mif -noreorientation $output_folder/fod_in_template_space_NOT_REORIENTED.mif -force

# Segment FOD images to estimate fixels and their apparent fibre density (FD) ## 
rm $output_folder/fixel_in_template_space_NOT_REORIENTED/*
fod2fixel -mask $group_folder_dwi/template_mask.mif $output_folder/fod_in_template_space_NOT_REORIENTED.mif $output_folder/fixel_in_template_space_NOT_REORIENTED -afd fd.mif -force

# Reorient fixels ## 
rm $output_folder/fixel_in_template_space/*
fixelreorient $output_folder/fixel_in_template_space_NOT_REORIENTED $output_folder/subject2template_warp.mif $output_folder/fixel_in_template_space -force

# Assign subject fixels to template fixels ## 
fixelcorrespondence $output_folder/fixel_in_template_space/fd.mif $group_folder_dwi/fixel_mask $group_folder_dwi/fd $subject.mif -force

# Compute the fibre cross-section (FC) metric## 
warp2metric $output_folder/subject2template_warp.mif -fc $group_folder_dwi/fixel_mask $group_folder_dwi/fc $subject.mif -force

# Compute the log fibre cross-section (FC) metric## 
mkdir -p $group_folder_dwi/log_fc
mrcalc $group_folder_dwi/fc/$subject.mif -log $group_folder_dwi/log_fc/$subject.mif -force

# Compute a combined measure of fibre density and cross-section (FDC) metric## 
mkdir -p $group_folder_dwi/fdc
mrcalc $group_folder_dwi/fd/$subject.mif $group_folder_dwi/fc/$subject.mif -mult $group_folder_dwi/fdc/$subject.mif -force

## Perform whole-brain fibre tractography on the FOD template
#tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 $group_folder_dwi/wmfod_template.mif -seed_image $group_folder_dwi/template_mask.mif -mask $group_folder_dwi/template_mask.mif -select 20000000 -cutoff 0.06 $group_folder_dwi/tracks_20_million.tck -force
#
#### Step 20 Reduce biases in tractogram densities
#command_21="tcksift /project/3022017.03/MRTrix3/Results/Group/tracks_20_million.tck /project/3022017.03/MRTrix3/Results/Group/wmfod_template.mif /project/3022017.03/MRTrix3/Results/Group/tracks_2_million_sift.tck -term_number 2000000"
#
## Submit to batch
#  echo "Submitting to batch..."
#  scriptname="/project/3022017.03/MRTrix3/tmpscripts/mrtrix_script$RANDOM"
#  #echo "$command_1" > $scriptname
#  #echo "$command_2a" >> $scriptname
#  #echo "$command_2b" >> $scriptname
#  #echo "$command_2c" >> $scriptname
#  #echo "$command_2d" >> $scriptname
#  #echo "$command_3" >> $scriptname
#  #echo "$command_4" >> $scriptname
#  #echo "$command_6" >> $scriptname
#  #echo "$command_7" >> $scriptname
#  #echo "$command_8" >> $scriptname
#  #echo "$command_9" >> $scriptname
#  #echo "$command_10" >> $scriptname
#  #echo "$command_13" > $scriptname
#  #echo "$command_14" >> $scriptname
#  #echo "$command_15" >> $scriptname
#  #echo "$command_16" >> $scriptname
#  #echo "$command_17" >> $scriptname
#  #echo "$command_18" >> $scriptname
#  #echo "$command_19" >> $scriptname
#  #echo "$command_20" > $scriptname
#  echo "$command_21" > $scriptname
#  chmod a+rwx $scriptname
#
#qsub -V -l walltime=50:00:00,mem=64gb $scriptname
##shift
##done
#
#
#
#
