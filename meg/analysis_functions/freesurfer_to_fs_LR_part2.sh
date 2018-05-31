#!/bin/bash

# this is adjusted by JM in order to make it MOUS-specific
# input arguments:
#  directory where the subject's freesurfer data can be found
#  directory that contains the target mesh
#  directory where the output should go
#
# this script assumes that the alignment has already been done
# and uses the results to also resample the freesurfer automatic
# parcellations of a2009s

set -x

export PATH=$PATH:$HOME/caret/bin_linux64

InputFsdir=$1

Fsdir=/opt/freesurfer/5.3
OutputRootDir=$2

Subject=`basename $InputFsdir`
SUBJECTS_DIR="$OutputRootDir"

# create some temporary directories for the lh and rh specific annotations,
# otherwise caret_command has trouble converting it into the appropriate paint files
#
# copy into these directories an original mesh, a registered mesh, a deformation map, and the annotation file
mkdir -p "$OutputRootDir"/"$Subject"/surf
mkdir -p "$OutputRootDir"/"$Subject"/label
mkdir -p "$OutputRootDir"/"$Subject"/label/lefthemi
mkdir -p "$OutputRootDir"/"$Subject"/label/righthemi

cp "$OutputRootDir"/"$Subject"/initial_mesh_to_164k_fs_LR.L.deform_map "$OutputRootDir"/"$Subject"/label/lefthemi/.
cp "$OutputRootDir"/"$Subject"/initial_mesh_to_164k_fs_LR.R.deform_map "$OutputRootDir"/"$Subject"/label/righthemi/.

cp "$OutputRootDir"/"$Subject"/"$Subject".L.white_orig.164k_fs_LR.coord.gii "$OutputRootDir"/"$Subject"/label/lefthemi/.
cp "$OutputRootDir"/"$Subject"/"$Subject".R.white_orig.164k_fs_LR.coord.gii "$OutputRootDir"/"$Subject"/label/righthemi/.

cp "$InputFsdir"/label/lh.aparc.a2009s.annot "$OutputRootDir"/"$Subject"/label/.
cp "$InputFsdir"/label/rh.aparc.a2009s.annot "$OutputRootDir"/"$Subject"/label/.

cp "$InputFsdir"/label/lh.aparc.a2009s.annot "$OutputRootDir"/"$Subject"/label/lefthemi/.
cp "$InputFsdir"/label/rh.aparc.a2009s.annot "$OutputRootDir"/"$Subject"/label/righthemi/.

cp "$InputFsdir"/surf/lh.white "$OutputRootDir"/"$Subject"/label/lefthemi/.
cp "$InputFsdir"/surf/rh.white "$OutputRootDir"/"$Subject"/label/righthemi/.

cp "$InputFsdir"/surf/lh.white "$OutputRootDir"/"$Subject"/surf/.
cp "$InputFsdir"/surf/rh.white "$OutputRootDir"/"$Subject"/surf/.

# convert annotation file into freesurfer label files
cd "$OutputRootDir"/"$Subject"/label/lefthemi
"$Fsdir"/bin/mri_annotation2label --subject "$Subject" --annotation lh.aparc.a2009s.annot --hemi lh --outdir .

# convert the label files into a caret paint file
caret_command -file-convert -fsl2c . lh.white lhlabels.paint

# apply the deformation map
caret_command -deformation-map-apply initial_mesh_to_164k_fs_LR.L.deform_map PAINT lhlabels.paint lhlabels164.paint

# do the same for the right hemisphere
cd "$OutputRootDir"/"$Subject"/label/righthemi
"$Fsdir"/bin/mri_annotation2label --subject "$Subject" --annotation rh.aparc.a2009s.annot --hemi rh --outdir .
caret_command -file-convert -fsl2c . rh.white rhlabels.paint
caret_command -deformation-map-apply initial_mesh_to_164k_fs_LR.R.deform_map PAINT rhlabels.paint rhlabels164.paint

