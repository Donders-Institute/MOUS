#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing processed corrmnebf data for $s"
  rsync -rvpt --remove-source-files /home/language/annhul/MOUS/meg/$s/corrmnebf/* $s/corrmnebf/
done  
