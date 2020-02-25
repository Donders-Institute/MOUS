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


set -- $subjectsB
for subject in $subjectsM;do
runnr="${1: -1}"
sname="${1:0:7}"
echo $subject $sname $runnr

# define some folder names and file names
output_folder=/project/3011020.09/processed/"$subject"/mri_dti/mrtrix
source_folder=/project/3013020.01/niftibox/DTI/"$sname"/"$runnr"/dd_basicproc/FDT_Data
anat_folder=/project/3011020.09/processed/"$subject"/meg/anatomy
fa_image=`ls "$source_folder"/fa*`
fa_template=/home/language/jansch/anaconda3/lib/python3.7/site-packages/tractseg/resources/MNI_FA_template.nii.gz

# create output_folder if needed
echo Creating directory "$output_folder"
mkdir -p $output_folder

# first coregistration step (+interpolation) to align the diffusion data with the FA template (needed for TractSeg)
flirt -ref $fa_template -in $fa_image -out "$output_folder"/fa_reg.nii.gz -omat "$output_folder"/fa2template.mat -dof 6 -cost mutualinfo -searchcost mutualinfo
flirt -ref $fa_template -in "$source_folder"/data.nii.gz -out "$output_folder"/data_reg.nii.gz -applyisoxfm 2.2 -init "$output_folder"/fa2template.mat -dof 6 -interp spline
rotate_bvecs -i "$source_folder"/bvecs -t "$output_folder"/fa2template.mat -o "$output_folder"/data_reg.bvecs
cp "$source_folder"/bvals "$output_folder"/data_reg.bvals

## convert the diffusion data to MRTrix's .mif format
mrconvert "$output_folder"/data_reg.nii.gz "$output_folder"/data_reg.mif -fslgrad "$output_folder"/data_reg.bvecs "$output_folder"/data_reg.bvals -force
rm "$output_folder"/data_reg.nii.gz

# extract the b0 volumes, and average -> originally this was needed for the coregistration to the anatomy, but we will use the FA image
dwiextract "$output_folder"/data_reg.mif -bzero "$output_folder"/b0.nii.gz -force
mrmath -axis 3 "$output_folder"/b0.nii.gz mean "$output_folder"/b0.nii.gz -force

# register the anatomy to the diffusion data, using the fa image
flirt -ref "$output_folder"/fa_reg.nii.gz -in "$anat_folder"/"$subject"coregMNI.nii -omat "$output_folder"/T1w2fa.mat -dof 6 -cost mutualinfo -searchcost mutualinfo -v
transformconvert "$output_folder"/T1w2fa.mat "$anat_folder"/"$subject"coregMNI.nii "$output_folder"/fa_reg.nii.gz flirt_import "$output_folder"/T1w2fa_final.txt -force
mrtransform -linear "$output_folder"/T1w2fa_final.txt "$anat_folder"/"$subject"coregMNI.nii "$output_folder"/T1w.nii.gz -force

# segmentation of the anatomical image
5ttgen fsl "$output_folder"/T1w.nii.gz "$output_folder"/5ttseg.nii.gz -tempdir "$output_folder" -force

# bias correction and brain mask creation
dwibiascorrect "$output_folder"/data_reg.mif "$output_folder"/data_reg.mif -ants -force
dwi2mask "$output_folder"/data_reg.mif "$output_folder"/data_mask.nii.gz -force

# response function estimation
dwi2response dhollander "$output_folder"/data_reg.mif "$output_folder"/ms_wm.txt "$output_folder"/ms_gm.txt "$output_folder"/ms_csf.txt -mask "$output_folder"/data_mask.nii.gz -tempdir "$output_folder" -force

# At this stage, it seems that the response functions need to be averaged across subjects, and the average response functions are used downstream.

## increase the voxel resolution as per the suggestion in the MRTrix documentation
#mrresize "$output_folder"/data_reg.mif -vox 1.25 "$output_folder"/data_reg_hr.mif
#dwi2mask "$output_folder"/data_reg_hr.mif "$output_folder"/data_mask_hr.mif -force
#
## fod estimation
#ss3t_csd_beta1 "$output_folder"/data_reg.mif "$output_folder"/ms_wm.txt "$output_folder"/wmfod.mif "$output_folder"/ms_gm.txt "$output_folder"/gm.mif "$output_folder"/ms_csf.txt "$output_folder"/csf.mif -mask "$output_folder"/data_mask.nii.gz -force
#mtnormalise "$output_folder"/wmfod.mif "$output_folder"/wmfod_norm.mif "$output_folder"/gm.mif "$output_folder"/gm_norm.mif "$output_folder"/csf.mif "$output_folder"/csf_norm.mif -mask "$output_folder"/data_mask.nii.gz -force
#
#
##shift
##done
#
#
###### Fixel Based Analysis steps #####
#
### Step 4: Computing tissue response functions ##
#
##command_4="dwi2response msmt_5tt $output_folder/data.mif $output_folder/5ttseg.mif $output_folder/ms_wm.txt $output_folder/ms_gm.txt $output_folder/ms_csf.txt -tempdir $output_folder/ -force"
#command_4a="dwibiascorrect -ants $output_folder/data.mif $output_folder/data.mif -force"
#command_4b="dwi2response dhollander $output_folder/data.mif $output_folder/ms_wm.txt $output_folder/ms_gm.txt $output_folder/ms_csf.txt -tempdir $output_folder/ -force"
#
### Step 5: Compute average response functions
##average_response C*/ms_wm.txt HC_group_average_response_wm.txt
##average_response C*/ms_gm.txt HC_group_average_response_gm.txt
##average_response C*/ms_csf.txt HC_group_average_response_csf.txt
#
### Step 6 Compute upsamples brain mask ##
#
#command_6="dwi2mask $output_folder/data.mif $output_folder/data_mask.mif -force"
#
### Step 7 FOD estimation (new fancy single shell, yet 3 tissue beta version code) ## 
#
##command_7="dwi2fod msmt_csd $output_folder/data.mif /project/3022017.03/MRTrix3/Results/Group/group_average_response_wm.txt $output_folder/wmfod.mif /project/3022017.03/MRTrix3/Results/Group/group_average_response_gm.txt $output_folder/gm.mif /project/3022017.03/MRTrix3/Results/Group/group_average_response_csf.txt $output_folder/csf.mif -mask $output_folder/data_mask.mif -force"
#command_7="ss3t_csd_beta1 $output_folder/data.mif $output_folder/ms_wm.txt $output_folder/wmfod.mif $output_folder/ms_gm.txt $output_folder/gm.mif $output_folder/ms_csf.txt $output_folder/csf.mif -mask $output_folder/data_mask.mif -force"
#
### Step 8 Joint bias field correction and intensity normalisation ## 
#
#command_8="mtnormalise $output_folder/wmfod.mif $output_folder/wmfod_norm.mif $output_folder/gm.mif $output_folder/gm_norm.mif $output_folder/csf.mif $output_folder/csf_norm.mif -mask $output_folder/data_mask.mif -force"
#
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
