#!/bin/sh
#$ -j y
#$ -o /scratch/home/r/rv519/logs
#$ -N sup_fast_job

# initialise whatever might be needed
if [ -z "${FSLDIR}" ]; then . /etc/fsl/5.0/fsl.sh; fi

# setup defaults
do_bet=yes;
betfparam=0.3;
strongbias=yes;
niter=5;
smooth=10;
type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

T1=$1 # take first input argument as input image
type=$2

# make sure input image doesn't have extension
T1=$(dirname $T1)'/'$(basename $T1 | cut -f1 -d'.')

# change to tmp working directory
wkdir=$(dirname $T1)'/'$(basename $T1)'_fast'
mkdir -p $wkdir
cd $wkdir

# print out input arguments
echo $T1
echo $type

#----------------------------------------------------------------------------

quick_smooth() {
  in=$1
  out=$2
  fslmaths $in -subsamp2 -subsamp2 -subsamp2 -subsamp2 vol16
  flirt -in vol16 -ref $in -out $out -noresampblur -applyxfm -paddingsize 16
  # possibly do a tiny extra smooth to $out here?
  imrm vol16
}

#----------------------------------------------------------------------------

fslmaths ${T1} -mul 0 lesionmask
fslmaths lesionmask -bin lesionmask
fslmaths lesionmask -binv lesionmaskinv

#### BIAS FIELD CORRECTION (main work, although also refined later on if segmentation run)
# required input: ${T1}
# output: ${T1}_biascorr  [ other intermediates to be cleaned up ]

if [ $strongbias = yes ] ; then

	# for the first step (very gross bias field) don't worry about the lesionmask
	# the following is a replacement for : fslmaths ${T1} -s 20 ${T1}_s20
	quick_smooth ${T1} ${T1}_s20
	fslmaths ${T1} -div ${T1}_s20 ${T1}_hpf
	if [ $do_bet = yes ] ; then
        # get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
	    bet ${T1}_hpf ${T1}_hpf_brain -R -m -f ${betfparam} -g -0.1
	    imcp ${T1}_hpf_brain ${T1}_brain # make a copy so can check brain extraction
	else
	    fslmaths ${T1}_hpf ${T1}_hpf_brain
	    fslmaths ${T1}_hpf_brain -bin ${T1}_hpf_brain_mask
	fi
	fslmaths ${T1}_hpf_brain_mask -mas lesionmaskinv ${T1}_hpf_brain_mask
    # get a smoothed version without the edge effects
	fslmaths ${T1} -mas ${T1}_hpf_brain_mask ${T1}_hpf_s20
	quick_smooth ${T1}_hpf_s20 ${T1}_hpf_s20
	quick_smooth ${T1}_hpf_brain_mask ${T1}_initmask_s20
	fslmaths ${T1}_hpf_s20 -div ${T1}_initmask_s20 -mas ${T1}_hpf_brain_mask ${T1}_hpf2_s20
	fslmaths ${T1} -mas ${T1}_hpf_brain_mask -div ${T1}_hpf2_s20 ${T1}_hpf2_brain
	# make sure the overall scaling doesn't change (equate medians)
	med0=$(fslstats ${T1} -k ${T1}_hpf_brain_mask -P 50)
    med1=$(fslstats ${T1}_hpf2_brain -k ${T1}_hpf_brain_mask -P 50)
	fslmaths ${T1}_hpf2_brain -div $med1 -mul $med0 ${T1}_hpf2_brain
	
	fslmaths ${T1}_hpf2_brain -mas lesionmaskinv ${T1}_hpf2_maskedbrain
	fast -o ${T1}_initfast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_hpf2_maskedbrain
	fslmaths ${T1}_initfast_restore -mas lesionmaskinv ${T1}_initfast_maskedrestore
	fast -o ${T1}_initfast2 -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast_maskedrestore
	fslmaths ${T1}_hpf_brain_mask ${T1}_initfast2_brain_mask
else
	if [ $do_bet = yes ] ; then
        # get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
	    bet ${T1} ${T1}_initfast2_brain -R -m -f ${betfparam} -g -0.1
	else
	    fslmaths ${T1} ${T1}_initfast2_brain
	    fslmaths ${T1}_initfast2_brain -bin ${T1}_initfast2_brain_mask
	fi
	fslmaths ${T1}_initfast2_brain ${T1}_initfast2_restore
fi

# redo fast again to try and improve bias field
fslmaths ${T1}_initfast2_restore -mas lesionmaskinv ${T1}_initfast2_maskedrestore
fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast2_maskedrestore

# use the latest fast output
fslmaths ${T1} -div ${T1}_fast_restore -mas ${T1}_initfast2_brain_mask ${T1}_fast_totbias
fslmaths ${T1}_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv ${T1}_initfast2_brain_mask2
fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias 
fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_initfast2_brain_mask2 -o ${T1}_fast_bias
fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias 
fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias 
# fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_initfast2_brain_mask -dilall -add 1 ${T1}_fast_bias  # alternative to fslsmoothfill
fslmaths ${T1} -div ${T1}_fast_bias ${T1}_biascorr

# clean up
imrm ${T1}_fast_restore ${T1}_fast_seg ${T1}_biascorr_bet_mask ${T1}_biascorr_bet ${T1}_biascorr_brain_mask2 ${T1}_biascorr_init ${T1}_biascorr_maskedbrain ${T1}_biascorr_to_std_sub \
  ${T1}_fast_bias_idxmask ${T1}_fast_bias ${T1}_fast_bias_init ${T1}_fast_bias_vol2 ${T1}_fast_bias_vol32 ${T1}_fast_totbias ${T1}_hpf* ${T1}_initfast* ${T1}_s20 ${T1}_initmask_s20 \
  lesionmask lesionmaskinv 
rm -rf $wkdir
  

