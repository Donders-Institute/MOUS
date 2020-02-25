#! /bin/sh

# These lists contain the matching IDs of the subjects known in BIG, and MOUS respectively
BINDIR=/home/language/jansch/projects/mous/bin
subjectsM=`cat "$BINDIR"/subjectlist_MOUS.txt`
scriptname="$BINDIR"/mous_tractseg.sh

# Set the environment
source /home/language/jansch/.bashrc
module load gcc
module load mrtrix

for subject in $subjectsM
do
  echo $subject

  # run job on the cluster
  echo "$scriptname $subject $sname $runnr" | qsub -l nodes=1:ppn=4,walltime=08:00:00,mem=20gb -N mrtrix_"$subject"
done

