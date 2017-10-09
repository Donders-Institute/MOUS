#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing processed anatomy data for $s"
  rsync -rvp --remove-source-files ~annhul/MOUS/meg/$s/anatomy/* $s/anatomy/
done  
