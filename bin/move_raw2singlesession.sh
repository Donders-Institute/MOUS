#!/bin/bash

ROOTDIR=/project/3011020.09/raw
cd $ROOTDIR
SUBJ=sub-*
for s in $SUBJ
do
  echo "Moving raw data for $s"
  #mkdir -p $ROOTDIR/$s/ses-meg01
  #mv $ROOTDIR/$s/ses-meg02/* $ROOTDIR/$s/ses-meg01
  #mv $ROOTDIR/$s/ses-meg03/* $ROOTDIR/$s/ses-meg01
  #mv $ROOTDIR/$s/ses-meg04/* $ROOTDIR/$s/ses-meg01
  mv $ROOTDIR/sub-2125/ses-meg01/"$s"* $ROOTDIR/$s/ses-meg01
done  
