#!/bin/bash

ROOTDIR=$1
TARGETDIR=$2
FOLDER=$3
cd $ROOTDIR
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing data for $s from $FOLDER folder on $ROOTDIR to $TARGETDIR"
  rsync -rvpu --remove-source-files $ROOTDIR/$s/$FOLDER/* $TARGETDIR/$s/$FOLDER/
done  
