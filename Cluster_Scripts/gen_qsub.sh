#!/bin/bash
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N generic_job

# initialise whatever might be needed
#if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi
if [ -z "${FREESURFERHOME}" ]; then . /etc/freesurfer/6.0/freesurfer.sh;  export TMPDIR='/tmp'; fi

#mri_robust_template --mov \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/GW_16CH_T1_1_biascorr.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/GW_16CH_T1_2_biascorr.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/GW_16CH_T1_3_biascorr.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/GW_8CH_T1_rob_biascorr_2_Avg_T1.nii.gz' \
#  --template '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/Avg_T1_w8ch.nii.gz' \
#  --average 1 --satit --iscale



export SUBJECTS_DIR=/scratch/groups/Projects/P1283/Data_2018/Anatomy
recon-all -subjid R3517_w8 -all -i '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol_FS/Avg_T1_w8ch.nii.gz'

#AnatomicalAverage -n --noclean \
#  -w '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol/tmpDir' \
#  -s '/usr/share/fsl/data/standard/MNI152_T1_1mm.nii.gz' \
#  -m '/usr/share/fsl/data/standard/MNI152_T1_1mm_brain_mask_dil.nii.gz' \
#  -o '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/refVol/Avg_T1.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/fast/GW_16CH_T1_1_biascorr_rob.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/fast/GW_16CH_T1_2_biascorr_rob.nii.gz' \
#  '/scratch/groups/Projects/P1283/Data_2018/Anatomy/Pre_FS/R3517/fast/GW_16CH_T1_3_biascorr_rob.nii.gz'
