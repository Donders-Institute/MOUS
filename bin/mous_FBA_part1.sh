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
mask_image=`ls "$source_folder"/nodif_brain_mask.nii.gz`
fa_template=/home/language/jansch/anaconda3/lib/python3.7/site-packages/tractseg/resources/MNI_FA_template.nii.gz

# create output_folder if needed
echo Creating directory "$output_folder"
mkdir -p $output_folder

## first coregistration step (+interpolation) to align the diffusion data with the FA template (needed for TractSeg)
#flirt -ref $fa_template -in $fa_image -out "$output_folder"/fa_reg.nii.gz -omat "$output_folder"/fa2template.mat -dof 6 -cost mutualinfo -searchcost mutualinfo
#flirt -ref $fa_template -in "$source_folder"/data.nii.gz -out "$output_folder"/data_reg.nii.gz -applyisoxfm 2.2 -init "$output_folder"/fa2template.mat -dof 6 -interp spline
#rotate_bvecs -i "$source_folder"/bvecs -t "$output_folder"/fa2template.mat -o "$output_folder"/data_reg.bvecs
#cp "$source_folder"/bvals "$output_folder"/data_reg.bvals
flirt -ref "$fa_template" -in "$mask_image" -out "$output_folder"/data_mask.nii.gz -applyisoxfm 2.2 -init "$output_folder"/fa2template.mat -dof 6 -interp nearestneighbour


### convert the diffusion data to MRTrix's .mif format
#mrconvert "$output_folder"/data_reg.nii.gz "$output_folder"/data_reg.mif -fslgrad "$output_folder"/data_reg.bvecs "$output_folder"/data_reg.bvals -force
#rm "$output_folder"/data_reg.nii.gz

## extract the b0 volumes, and average -> originally this was needed for the coregistration to the anatomy, but we will use the FA image
#dwiextract "$output_folder"/data_reg.mif -bzero "$output_folder"/b0.nii.gz -force
#mrmath -axis 3 "$output_folder"/b0.nii.gz mean "$output_folder"/b0.nii.gz -force

## register the anatomy to the diffusion data, using the fa image
#flirt -ref "$output_folder"/fa_reg.nii.gz -in "$anat_folder"/"$subject"coregMNI.nii -omat "$output_folder"/T1w2fa.txt -dof 6 -cost mutualinfo -searchcost mutualinfo -v
#transformconvert "$output_folder"/T1w2fa.txt "$anat_folder"/"$subject"coregMNI.nii "$output_folder"/fa_reg.nii.gz flirt_import "$output_folder"/T1w2fa_final.txt -force
#mrtransform -linear "$output_folder"/T1w2fa_final.txt "$anat_folder"/"$subject"coregMNI.nii "$output_folder"/T1w.nii.gz -force

## segmentation of the anatomical image
#5ttgen fsl "$output_folder"/T1w.nii.gz "$output_folder"/5ttseg.nii.gz -tempdir "$output_folder" -force

## bias correction and brain mask creation
dwibiascorrect "$output_folder"/data_reg.mif "$output_folder"/data_reg.mif -mask "$output_folder"/data_mask.nii.gz -ants -tempdir /tmp -force

## response function estimation
#dwi2response dhollander "$output_folder"/data_reg.mif "$output_folder"/ms_wm.txt "$output_folder"/ms_gm.txt "$output_folder"/ms_csf.txt -mask "$output_folder"/data_mask.nii.gz -tempdir "$output_folder" -force

# the response functions need to be averaged across subjects, and the average response functions are to be used downstream, for a fair quantitative comparison

