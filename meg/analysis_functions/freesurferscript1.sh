#!/bin/sh

export FREESURFER_HOME=/opt/freesurfer-v5.1
export SUBJECTS_DIR=$1

source $FREESURFER_HOME/SetUpFreeSurfer.sh

mksubjdirs $SUBJECTS_DIR/$2

cd $SUBJECTS_DIR
cp $2coregMNI.nii $SUBJECTS_DIR/$2/mri/
cp $2coregMNIskullstrip.nii $SUBJECTS_DIR/$2/mri/

cd $SUBJECTS_DIR/$2/mri
mri_convert -c -oc 0 0 0 $2coregMNI.nii orig.mgz
mri_convert -c -oc 0 0 0 $2coregMNIskullstripmask.nii brainmask.mgz

recon-all -talairach -subjid $2
recon-all -nuintensitycor -subjid $2
recon-all -normalization -subjid $2
