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
sname=$2
runnr=$3

# define some folder names and file names
output_folder=/project/3011020.09/processed/"$subject"/mri_dti/mrtrix
source_folder=/project/3013020.01/niftibox/DTI/"$sname"/"$runnr"/dd_basicproc/FDT_Data
anat_folder=/project/3011020.09/processed/"$subject"/meg/anatomy
fa_image=`ls "$source_folder"/fa*`
fa_template=/home/language/jansch/anaconda3/lib/python3.7/site-packages/tractseg/resources/MNI_FA_template.nii.gz
scriptdir=`dirname "$0"`

wm="$scriptdir"/mous_avg198_response_wm.txt
gm="$scriptdir"/mous_avg198_response_gm.txt
csf="$scriptdir"/mous_avg198_response_csf.txt

## increase the voxel resolution as per the suggestion in the MRTrix documentation
#mrresize "$output_folder"/data_reg.mif -vox 1.25 "$output_folder"/data_reg_hr.mif
#dwi2mask "$output_folder"/data_reg_hr.mif "$output_folder"/data_mask_hr.mif -force

# fod estimation
ss3t_csd_beta1 "$output_folder"/data_reg.mif $wm "$output_folder"/wmfod.mif $gm "$output_folder"/gm.mif $csf "$output_folder"/csf.mif -mask "$output_folder"/data_mask.nii.gz -scratch /tmp/ -force
mtnormalise "$output_folder"/wmfod.mif "$output_folder"/wmfod_norm.mif "$output_folder"/gm.mif "$output_folder"/gm_norm.mif "$output_folder"/csf.mif "$output_folder"/csf_norm.mif -mask "$output_folder"/data_mask.nii.gz -force

## Symbolic link all FOD images and masks into a single input folder #
##ln -sr $output_folder/wmfod_norm.mif /project/3022017.03/MRTrix3/Results/Group/fod_input/$subject.mif 
##ln -sr $output_folder/data_mask.mif /project/3022017.03/MRTrix3/Results/Group/mask_input/$subject.mif
#
## Step 9  Run the template building script #
#
#command_9="population_template /project/3022017.03/MRTrix3/Results/Group/fod_input /project/3022017.03/MRTrix3/Results/Group/wmfod_template.mif -mask_dir /project/3022017.03/MRTrix3/Results/Group/mask_input -voxel_size 1.25 -tempdir /project/3022017.03/MRTrix3/Results/Group/tempdir -continue /project/3022017.03/MRTrix3/Results/Group/tempdir warps_6/199655.mif -nocleanup -force > /project/3022017.03/MRTrix3/Results/Group/population_template.log 2>&1"
#
### Step 10 Register all subject FOD images to the FOD template ## 
#command_10="mrregister $output_folder/wmfod_norm.mif -mask1 $output_folder/data_mask.mif /project/3022017.03/MRTrix3/Results/Group/wmfod_template.mif -nl_warp $output_folder/subject2template_warp.mif $output_folder/template2subject_warp.mif -force"
#
### Step 11 Compute the template mask ## 
## Warp all masks into template space:
##mrtransform $output_folder/data_mask.mif -warp $output_folder/subject2template_warp.mif -interp nearest -datatype bit $output_folder/dwi_mask_in_template_space.mif -force
##mrmath */dwi_mask_in_template_space.mif min template/template_mask.mif -datatype bit 
#
### Step 12 Compute a white matter template analysis fixel mask ## 
## first CD to main directory #
##fod2fixel -mask Group/template_mask.mif -fmls_peak_value 0.06 Group/wmfod_template.mif Group/fixel_mask
## Now check output as described in manual (mrview open template/fixel_mask/index.mif with fixel plot tool and check whether fixels are missing, and:
##mrinfo -size Group/fixel_mask/directions.mif ## expected to have 100.000 fixels 
#
### Step 13 Warp FOD images to template space ## 
#command_13="mrtransform $output_folder/wmfod_norm.mif -warp $output_folder/subject2template_warp.mif -noreorientation $output_folder/fod_in_template_space_NOT_REORIENTED.mif -force"
#
### Step 14 Segment FOD images to estimate fixels and their apparent fibre density (FD) ## 
#command_14="fod2fixel -mask /project/3022017.03/MRTrix3/Results/Group/template_mask.mif $output_folder/fod_in_template_space_NOT_REORIENTED.mif $output_folder/fixel_in_template_space_NOT_REORIENTED -afd fd.mif -force"
#
### Step 15 Reorient fixels ## 
#command_15="fixelreorient $output_folder/fixel_in_template_space_NOT_REORIENTED $output_folder/subject2template_warp.mif $output_folder/fixel_in_template_space"
#
### Step 16 Assign subject fixels to template fixels ## 
#command_16="fixelcorrespondence $output_folder/fixel_in_template_space/fd.mif /project/3022017.03/MRTrix3/Results/Group/fixel_mask /project/3022017.03/MRTrix3/Results/Group/fd $subject.mif -force"
#
### Step 17 Compute the fibre cross-section (FC) metric## 
#command_17="warp2metric $output_folder/subject2template_warp.mif -fc /project/3022017.03/MRTrix3/Results/Group/fixel_mask /project/3022017.03/MRTrix3/Results/Group/fc $subject.mif -force"
#
### Step 18 Compute the log fibre cross-section (FC) metric## 
#command_18="mrcalc /project/3022017.03/MRTrix3/Results/Group/fc/$subject.mif -log /project/3022017.03/MRTrix3/Results/Group/log_fc/$subject.mif"
#
### Step 19 Compute a combined measure of fibre density and cross-section (FDC) metric## 
#command_19="mrcalc /project/3022017.03/MRTrix3/Results/Group/fd/$subject.mif /project/3022017.03/MRTrix3/Results/Group/fc/$subject.mif -mult /project/3022017.03/MRTrix3/Results/Group/fdc/$subject.mif"
#
### Step 20 Perform whole-brain fibre tractography on the FOD template
#command_20="tckgen -angle 22.5 -maxlen 250 -minlen 10 -power 1.0 /project/3022017.03/MRTrix3/Results/Group/wmfod_template.mif -seed_image /project/3022017.03/MRTrix3/Results/Group/template_mask.mif -mask /project/3022017.03/MRTrix3/Results/Group/template_mask.mif -select 20000000 -cutoff 0.06 /project/3022017.03/MRTrix3/Results/Group/tracks_20_million.tck -force"
#
### Step 20 Reduce biases in tractogram densities
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
