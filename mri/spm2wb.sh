#!/bin/sh

# spm2wb.sh converts an SPM volume into a cifti file that can be viewed with wb_view.
# The volumetric space is assumed to be compatible with the space that defines the
# Conte69 midthickness cortical sheet. This sheet shows a nice overlay with the T1.nii
# volume from SPM8.
# Usage: spm2wb.sh inputfilename

# set the paths
export PATH=$PATH:/project/3011020.09/workbench/bin_rh_linux64
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/project/3011020.09/workbench/libs_rh_linux64

FILEPATH=`dirname $1`
FILENAME=`basename $1`
FILENAME=`echo "$FILENAME" | cut -d'.' -f1`
NIFTINAME="$FILEPATH"/"$FILENAME".nii.gz
GIFTINAME1="$FILEPATH"/"$FILENAME".L.gii
GIFTINAME2="$FILEPATH"/"$FILENAME".R.gii
CIFTINAME="$FILEPATH"/"$FILENAME".dscalar.nii

mri_convert $1 $NIFTINAME
wb_command -volume-to-surface-mapping $NIFTINAME /project/3011020.09/32k_ConteAtlas_v2/Conte69.L.midthickness.32k_fs_LR.surf.gii $GIFTINAME1 -trilinear
wb_command -volume-to-surface-mapping $NIFTINAME /project/3011020.09/32k_ConteAtlas_v2/Conte69.R.midthickness.32k_fs_LR.surf.gii $GIFTINAME2 -trilinear
wb_command -cifti-create-dense-scalar $CIFTINAME -left-metric $GIFTINAME1 -right-metric $GIFTINAME2

