#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N bet_job

# initialise whatever might be needed
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi

inFile=$1
outFile=$2
bParam=$3

bet $inFile $outFile $bParam
