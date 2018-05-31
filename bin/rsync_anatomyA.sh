#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=A2*
for s in $SUBJ
do
  echo "Rsyncing processed anatomy data for $s"
  rsync -rvpu --remove-source-files ~annhul/MOUS/meg/$s/anatomy/* $s/anatomy/
done  
