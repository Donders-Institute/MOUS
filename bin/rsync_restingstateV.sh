#!/bin/bash

ROOTDIR=$1
cd $ROOTDIR
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing processed restingstate data for $s"
  rsync -rvpu --remove-source-files /project/3011020.09/MEG/$s/restingstate/* $s/restingstate/
done  
