#!/bin/sh

SUBJ="$1"
TDIR=/home/language/jansch/anaconda3/lib/python3.7/site-packages/tractseg/resources
OUTDIR="$2"/"$SUBJ"

mkdir "$OUTDIR"/tractseg
cd "$OUTDIR"
calc_FA -i dmri/dwi.nii.gz -o tractseg/FA.nii.gz --bvals dmri/bvals --bvecs dmri/bvecs --brain_mask dmri/nodif_brain_mask.nii.gz
flirt -ref "$TDIR"/MNI_FA_template.nii.gz -in tractseg/FA.nii.gz -out tractseg/FA_MNI.nii.gz -omat tractseg/FA_2_MNI.mat -dof 6 -cost mutualinfo -searchcost mutualinfo
flirt -ref "$TDIR"/MNI_FA_template.nii.gz -in dmri/dwi.nii.gz -out tractseg/Diffusion_MNI.nii.gz -applyisoxfm 2.2 -init tractseg/FA_2_MNI.mat -dof 6 -interp spline
rotate_bvecs -i dmri/bvecs -t tractseg/FA_2_MNI.mat -o tractseg/Diffusion_MNI.bvecs
cp dmri/bvals tractseg/Diffusion_MNI.bvals
flirt -ref "$TDIR"/MNI_FA_template.nii.gz -in dmri/nodif_brain_mask.nii.gz -out tractseg/nodif_brain_mask_MNI.nii.gz -applyisoxfm 2.2 -init tractseg/FA_2_MNI.mat -dof 6 -interp nearestneighbour

TractSeg -i tractseg/Diffusion_MNI.nii.gz -o "$OUTDIR"/tractseg --raw_diffusion_input --output_type tract_segmentation --brain_mask tractseg/nodif_brain_mask_MNI.nii.gz
TractSeg -i tractseg/peaks.nii.gz -o "$OUTDIR"/tractseg --output_type endings_segmentation --brain_mask tractseg/nodif_brain_mask_MNI.nii.gz
TractSeg -i tractseg/peaks.nii.gz -o "$OUTDIR"/tractseg --output_type TOM --brain_mask tractseg/nodif_brain_mask_MNI.nii.gz
Tracking -i tractseg/peaks.nii.gz -o "$OUTDIR"/tractseg --nr_fibers 5000
cd "$OUTDIR"/tractseg
Tractometry -i TOM_trackings/ -o "$SUBJ"_tractometry.csv -e endings_segmentations/ -s FA.nii.gz
