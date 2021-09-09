#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N fast_job

# initialise whatever might be needed
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi

# FAST example
inFile=$1
type=$2

echo $inFile
echo $type

# make sure input image doesn't have extension
inFile=$(echo $inFile | cut -f1 -d'.')

fast -t $type -n 3 -H 0.1 -I 5 -l 10.0 --nopve -B -o $inFile $inFile

