#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N bbr_flirt_job

set -e

# make sure fsl/freesurfer initialised
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi
if [ -z "${FREESURFER_HOME}" ]; then . /etc/freesurfer/6.0/freesurfer.sh;  export TMPDIR='/tmp'; fi

# parse inputs
export SUBJECTS_DIR=$1
SUBJ=$2     # subject
mov=$3      # volume to register to T1
reg=$4      # registration output, e.g. <...>/register.dat/lta
contrast=$5 # t1/t2/bold/dti
add_opt=$6  # any additional options, e.g. '--epi-mask' or '--init-reg <...> '

bbregister --s $SUBJ --mov $mov --reg $reg --$contrast