#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N bbr_flirt_job

set -e

# make sure fsl initialised
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi

wkDir=$1
inFile=$2
refFile=$3
wmSeg=$4
bbrSlope=$5 # -0.5 for epi/PD etc, 0.5 for T1w

inName=$(basename $inFile .nii.gz)
refName=$(basename $refFile .nii.gz)

sAng=90

# delete any existing files with same name
rm -f $wkDir'/'$inName'_2_'$refName'_init.'*
rm -f $wkDir'/'$inName'_2_'$refName'_bbr.'*

# initial flirt
flirt \
  -in $inFile \
  -ref $refFile \
  -omat $wkDir'/'$inName'_2_'$refName'_init.mat' \
  -bins 256 -cost normmi -searchrx -$sAng $sAng -searchry -$sAng $sAng -searchrz -$sAng $sAng -dof 6 -interp spline
  
# bbr flirt
flirt \
  -in $inFile \
  -ref $refFile \
  -wmseg $wmSeg \
  -init $wkDir'/'$inName'_2_'$refName'_init.mat' \
  -out $wkDir'/'$inName'_2_'$refName'_bbr.nii.gz' \
  -omat $wkDir'/'$inName'_2_'$refName'_bbr.mat' \
  -schedule '/usr/share/fsl-5.0/etc/flirtsch/bbr.sch' \
  -cost bbr -bbrslope $bbrSlope -dof 6 -interp spline
  
# cleanup init files
rm -f $wkDir'/'$inName'_2_'$refName'_init.'*

