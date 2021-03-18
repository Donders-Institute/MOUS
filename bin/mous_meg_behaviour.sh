#!/bin/sh

LOGDIR=/project/3011020.09/bids/sourcedata/meg_task

subs=`cat subjectlist_MOUS.txt`
touch MOUS_meg_behaviour.txt
for subj in $subs
do
  #echo $(grep QUESTION $LOGDIR/$subj*.log | wc -l)/2 |bc
  echo -e "$subj\t$val" >> MOUS_meg_behaviour.txt
  echo "scale=4;100-100*$(grep incorrect $LOGDIR/$subj*.log | wc -l)/$(grep QUESTION $LOGDIR/$subj*.log | wc -l)" |bc >> MOUS_meg_behaviour.txt
done
