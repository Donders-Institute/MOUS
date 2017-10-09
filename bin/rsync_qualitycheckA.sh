#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=A*

for s in $SUBJ
do
  echo "Rsyncing qualitycheck data for $s"
  rsync -rvpu --remove-source-files ~annhul/MOUS/meg/$s/qualitycheck/* $s/qualitycheck/
done  
