#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N flirt_job

# make sure fsl initialised
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi

wkDir=$1
inFile=$2
refFile=$3

inName=$(basename $inFile .nii.gz)
refName=$(basename $refFile .nii.gz)

echo $wkDir
echo $inFile
echo $refFile
echo $inName
echo $refName

sAng=30

flirt \
  -in $inFile \
  -ref $refFile \
  -out $wkDir'/'$inName'_2_'$refName'.nii.gz' \
  -omat $wkDir'/'$inName'_2_'$refName'.mat' \
  -bins 256 -cost mutualinfo -searchrx -$sAng $sAng -searchry -$sAng $sAng -searchrz -$sAng $sAng -dof 6 -interp spline
  
# sinc -sincwidth 7 -sincwindow hanning
