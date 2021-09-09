#!/bin/bash

set -e

#----------------------------------------------------------------
# parse input

# create usage subfunction
usage() {
echo ""
echo "Script to create an edge outline from the input image"
echo ""
echo "Usage: createEdge [OPTION]... -i [FILE]..."
echo ""
echo "Required arguments (You must specify one or more of):"
echo "  -i <file>,  input volume to be processed"
echo ""
echo "Optional arguments (You may optionally specify one or more of):"
echo "  -h,         display this help, then exit"
echo "  -s,         simple mode - just creates an edge, nothing fancy"
echo "  -t,         toggle (turn off) thresholding (-thrP 2 bit)"
echo "  -o <file>,  specifiy name of output file (by default is <input>_edge)"
echo ""
echo "By default it will do some cleanup before finding edge:"
echo "- Removes spurious pixels (-thrP 2, -ero) and isolated clusters"
echo "- Fills holes (-fillh)"
echo "- Smooths outline (-dilF)"
echo ""
echo "Simple mode just finds the edge with input 'as is' (via -edge -bin -mas combo)"
echo "- better for fine structures, e.g. white matter segmentations"
echo ""
}

# make sure at least some input arguments set
if [ $# -eq 0 ]; then
	usage
	exit 1
fi

# set defaults
simpleMode=0
useThreshold=1
altOutputName=0

while getopts ":i:sto:h" arg; do
  case $arg in
    i) # Specify input
      in=$OPTARG
      ;;
    s) # Specify simple mode
      simpleMode=1
      ;;
    t) # turn off thresholding
      useThreshold=0
      ;;
    o) # Specify output
      altOutputName=1
      out=$OPTARG
      ;;
    h | *) # Display help.
      usage
      exit 0
      ;;
  esac
done

# make sure input set
if [[ -z $in ]]; then
  echo "No input set"
  usage
  exit 1
fi

#----------------------------------------------------------------

# grab dirname and basename, plus datestamp for tmp files
inDir=$(dirname $in)
inBase=$(basename $in | cut -f1 -d'.')
dStamp=$(date +%y%m%d)

# set out template
outTemplate=$inDir'/'$inBase'_'$dStamp

# set out name if needed
if [[ $altOutputName -eq 0 ]]; then
  out=$inDir'/'$inBase'_edge'
fi

#----------------------------------------------------------------
# first step (if not in simple mode) - remove all holes in brain image...

if [[ $simpleMode -eq 0 ]]; then

  # first threshold to remove really low values, then binarise and erode once
  if [[ $useThreshold -eq 1 ]]; then
    fslmaths $in -thrP 2 -bin -ero $outTemplate'_mask'
  else
    fslmaths $in -bin -ero $outTemplate'_mask'
  fi

  # remove any spurious clusters
  cluster -i $outTemplate'_mask' -t 0.5 --no_table -o $outTemplate'_clusters'
  maxClust=$(fslstats $outTemplate'_clusters' -R | cut -d' ' -f2)
  clustThresh=$(echo $maxClust - 0.5 | bc -l)
  fslmaths $outTemplate'_clusters' -thr $clustThresh -bin $outTemplate'_mask'

  # fill any holes, dilate to undo previous erosion, fill holes again to be extra careful
  fslmaths $outTemplate'_mask' -fillh -dilF -fillh $outTemplate'_mask'
  
  # overwrite 'in' with new mask
  in=$outTemplate'_mask'
  
fi

#----------------------------------------------------------------
# now create actual outline

fslmaths $in -edge -bin -mas $in $out

# clean up
rm -f $outTemplate*
