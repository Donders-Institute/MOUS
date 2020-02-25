#!/bin/sh

LIST=`cat subjectlist_BIG.txt`
BINDIR=/project/3013020.01/niftibox/sMRI/FreeSurfer_v53/tracula/bin/scripts_mous
DATADIR=/project/3013020.01/niftibox/sMRI/FreeSurfer_v53/tracula

for subj in $LIST
do
  # check the runs
  RUNS=`ls -d ${DATADIR}/${subj}*`
  for run in $RUNS
  do
    thisrun="${run: -1}"
    
    SUBJ="$subj"_"$thisrun"
    
    # run job on the cluster
    echo "$BINDIR/script_tractseg.sh $SUBJ $DATADIR" | qsub -l nodes=1:ppn=4,walltime=08:00:00,mem=20gb -N tractseg_"$SUBJ"

  done
done

