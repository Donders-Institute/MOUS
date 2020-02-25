#!/bin/sh

SUBJ="$1"
TDIR=/home/language/jansch/anaconda3/lib/python3.7/site-packages/tractseg/resources
OUTDIR=/project/3011020.09/processed/"$SUBJ"/mri_dti
MRTRIXDIR="$OUTDIR"/mrtrix

mkdir -p "$OUTDIR"/tractseg
cd "$OUTDIR"/tractseg

sh2peaks -mask "$MRTRIXDIR"/data_mask.nii.gz "$MRTRIXDIR"/wmfod_norm.mif peaks.nii.gz
rsync "$MRTRIXDIR"/data_mask.nii.gz data_mask.nii.gz 

TractSeg -i peaks.nii.gz -o . --output_type tract_segmentation --brain_mask data_mask.nii.gz
TractSeg -i peaks.nii.gz -o . --output_type endings_segmentation --brain_mask data_mask.nii.gz
TractSeg -i peaks.nii.gz -o . --output_type TOM --brain_mask data_mask.nii.gz
Tracking -i peaks.nii.gz -o . --nr_fibers 2000
