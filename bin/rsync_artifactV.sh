#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=V*
#SUBJ=V1001
for s in $SUBJ
do
  echo "Rsyncing processed artifact data for $s"
  rsync -rvpu --remove-source-files ~annhul/MOUS/meg/$s/artifact/* $s/artifact/
done  
