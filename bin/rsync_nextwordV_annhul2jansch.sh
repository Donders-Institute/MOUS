#!/bin/bash

cd /project/3011020.09/annhul/
SUBJ=V*
for s in $SUBJ
do
  echo "Rsyncing processed erf data for $s"
  rsync -rvpt --remove-source-files /project/3011020.09/annhul/$s/erf/*nextword.mat /project/3011020.09/jansch/$s/erf/.
done  
