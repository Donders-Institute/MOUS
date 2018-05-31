#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing processed restingstate data for $s"
  rsync -rvpt --remove-source-files /home/language/jansch/public/mous/$s/bfica/* $s/bfica/
done  
