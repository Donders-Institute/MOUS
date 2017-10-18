#!/bin/bash

RAWDATADIR=/home/language/juludd/MOUS/rawdata

cd $RAWDATADIR
for d in A*
do
  cd $RAWDATADIR/$d
  mkdir -p mri_other
  mkdir -p mri_anatomy
  mkdir -p mri_restingstate
  mkdir -p mri_task
  mkdir -p mri_tractography
  mkdir -p mri_spectroscopy

  mkdir -p mri_anatomy/raw
  mkdir -p mri_restingstate/raw
  mkdir -p mri_task/raw
  mkdir -p mri_tractography/raw
  mkdir -p mri_spectroscopy/raw

  rsync -rvpu AA1 mri_other/.
  rsync -rvpu Localizer1 mri_other/.
  rsync -rvpu LOCALIZER mri_other/.
  rsync -rvpu TestingAudio mri_other/.
 
  rsync -rvpu Structural/* mri_anatomy/raw/.
  rsync -rvpu RestingState/* mri_restingstate/raw/.
  rsync -rvpu Functional/* mri_task/raw/.
  rsync -rvpu DTI/* mri_tractography/raw/.

  rsync -rvpu GABABROCALEFT mri_spectroscopy/raw/. 
  rsync -rvpu GABABROCARIGHT mri_spectroscopy/raw/. 
  rsync -rvpu GABAWERNICKELEFT mri_spectroscopy/raw/. 
  rsync -rvpu GABAWERNICKERIGHT mri_spectroscopy/raw/. 
  rsync -rvpu GABAV1LEFT mri_spectroscopy/raw/. 

  for subd in *
    do
      if #here comes the definition of the rule that identifies whether subd is a leftover directory, when this is so, copy it into mri_otehr
        rsync -rvpu $subd mri_other/.
      fi
    done 
done
