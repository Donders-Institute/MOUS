#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=A*
for s in $SUBJ
do
  echo "Rsyncing raw data for $s"
  rsync -rvp --remove-source-files ~annhul/MOUS/meg/$s/RAW/* $s/RAW/
done  
