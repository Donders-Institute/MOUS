#! /bin/sh

# These lists contain the matching IDs of the subjects known in BIG, and MOUS respectively
BINDIR=/home/language/jansch/projects/mous/bin
subjectsB=`cat "$BINDIR"/subjectlist_BIG_run.txt`
subjectsM=`cat "$BINDIR"/subjectlist_MOUS.txt`
#scriptname="$BINDIR"/mous_FBA_part1.sh
#scriptname="$BINDIR"/mous_FBA_part2_hr.sh
#scriptname="$BINDIR"/mous_FBA_part5_hr.sh
scriptname="$BINDIR"/mous_FBA_part7_hr.sh

# Set the environment
#source /home/language/jansch/.bashrc
module load gcc
module load mrtrix
module load ANTs

#subjectsM="A2058 A2061 A2113 V1005"
#subjectsM="A2007 A2030 A2038 A2050 A2077 V1029 V1030 V1044 V1050 V1080 V1088"
set -- $subjectsB
for subject in $subjectsM
do
  runnr="${1: -1}"
  sname="${1:0:7}"
  echo $subject $sname $runnr

  # run job on the cluster
  #echo "$scriptname $subject $sname $runnr" | qsub -l nodes=1:ppn=4,walltime=08:00:00,mem=8gb -N mrtrix_"$subject"
  #echo "$scriptname $subject" | qsub -l nodes=1:ppn=8,walltime=08:00:00,mem=12gb -N mrtrix_"$subject"
  source $scriptname $subject
  shift
done

