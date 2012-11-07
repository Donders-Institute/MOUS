export MNE_ROOT=/opt/mne-2.7.3/
cd $MNE_ROOT/bin
. ./mne_setup_sh
export SUBJECTS_DIR=$1
export SUBJECT=$2
./mne_setup_source_space --overwrite --ico -6
