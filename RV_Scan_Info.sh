#!/bin/bash

# set currFile to input given
currFile=$1

# run dcmdump and throw into a temporary file
dcmdump $currFile > '/tmp/tmp.txt'

# to extract key variables use:
# grep to get key line, cut to get third field (space delimiter), sed to strip square brackets
# NOTE: sed - think of [][] as [ ][ ] - i.e. ][ in brackets, use of ] stops it being special character
# the if [ -z $"..." ] tests if empty

fileName=$(basename $(dirname $currFile))

currTxt='RV INFO for '$fileName':'
echo ' '; echo $currTxt; echo $currTxt | sed 's/./-/g'; echo ' '

#---------------------------------------------------
# TR

myTR=$(grep -e 'RepetitionTime' -e '0018,0080' '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
if [ -z "$myTR" ]; then 
	echo 'Could not detect Repetition Time (TR)'
else
	echo 'Repetition Time (TR): '$myTR'ms'
fi

#---------------------------------------------------
# TE

myTE=$(grep -e 'EchoTime' -e '0018,0081' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
if [ -z "$myTE" ]; then 
	echo 'Could not detect Echo Time (TE)'
else
	echo 'Echo Time (TE): '$myTE'ms'
fi

#---------------------------------------------------
# TI

myTI=$(grep -e 'InversionTime' -e '0018,0082' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
if [ -z "$myTI" ]; then 
	myTI=0
fi

if [ $myTI -ne 0 ]; then 
	echo 'Inversion Time (TI): '$myTI'ms'
else
	echo 'Inversion Time (TI) not set/detected'
fi

#---------------------------------------------------
# Voxel size

myXY=$(grep -e 'PixelSpacing' -e '0028,0030' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g' | sed 's/\\/x/') # also replace \ with x
myZ=$(grep -e 'SliceThickness' -e '0018,0050' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
if [ -z "$myXY" ] && [ -z "$myZ" ]; then 
	echo 'Could not detect voxel size'
else
	echo 'Voxel Size: '$myXY'x'$myZ'mm^3'
fi


#---------------------------------------------------
# Flip Angle

myFA=$(grep -e 'FlipAngle' -e '0018,1314' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
if [ -z "$myFA" ]; then 
	echo 'Could not detect Flip Angle'
else
	echo 'Flip Angle: '$myFA'deg'
fi

#---------------------------------------------------
# Matrix size

usingMosaic=0

myIDX=$(grep -e 'ImageDimensionX' -e '0027,1060' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
myIDY=$(grep -e 'ImageDimensionY' -e '0027,1060' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
myIDZ=$(grep -e 'LocationsInAcquisition' -e '0021,104f' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')

# if ImageDimenxionX or ImageDimensionY not set, can grab from another header
if [ -z "$myIDX" ]; then 
	myIDX=$(grep -e 'AcquisitionMatrix' -e '0018,1310' -w '/tmp/tmp.txt' | cut -d' ' -f3 | cut -d'\' -f1)
fi
if [ "$myIDX" -eq 0 ]; then # may be 2nd field instead
	myIDX=$(grep -e 'AcquisitionMatrix' -e '0018,1310' -w '/tmp/tmp.txt' | cut -d' ' -f3 | cut -d'\' -f2)
fi
if [ -z "$myIDY" ]; then 
	myIDY=$(grep -e 'AcquisitionMatrix' -e '0018,1310' -w '/tmp/tmp.txt' | cut -d' ' -f3 | cut -d'\' -f4)
fi
if [ "$myIDY" -eq 0 ]; then # may be 3rd field instead
	myIDY=$(grep -e 'AcquisitionMatrix' -e '0018,1310' -w '/tmp/tmp.txt' | cut -d' ' -f3 | cut -d'\' -f3)
fi

if [ -z "$myIDZ" ]; then 
	# see if number of images in mosaic set
	myIDZ=$(grep '0019,100a' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g')
	usingMosaic=1
fi

if [ -z "$myIDX" ] || [ -z "$myIDY" ] || [ -z "$myIDZ" ]; then 
	echo 'Could not (fully?) detect matrix size - check FSL INFO output'
	if [ -z "$myIDX" ]; then myIDX='?'; fi
	if [ -z "$myIDY" ]; then myIDY='?'; fi
	if [ -z "$myIDZ" ]; then myIDZ='?'; fi
fi

if [ $usingMosaic -eq 0 ]; then
	echo 'Matrix Size: '$myIDX'x'$myIDY'x'$myIDZ
else
	echo 'Matrix Size: '$myIDX'x'$myIDY'x'$myIDZ' (using num. imgs in mosaic for z)'
fi

#---------------------------------------------------
# FOV

calcFOV=0

myFOV=$(grep -e 'DisplayFieldOfView' -e '0019,101e' -w '/tmp/tmp.txt' | cut -d' ' -f3 | sed 's/[][]//g' | sed 's/[.]0*//g') # also remove zeros after decimal place

if [ -z "$myFOV" ]; then 
	# first see if we can calculate it
	if [ ! -z "$myXY" ] && [ ! -z "$myIDX" ]; then
		tempX=$(echo $myXY | cut -d'x' -f1)
		myFOV=$(echo $tempX'*'$myIDX | bc)
		calcFOV=1
	fi
fi


if [ -z "$myFOV" ]; then 
	echo 'Could not detect Flip Angle'
else
	if [ $calcFOV -eq 0 ]; then
		echo 'FOV: '$myFOV'mm'
	else
		echo 'FOV: '$myFOV'mm (calculated based upon voxel size (x) * matrix size (X))'
	fi
fi

#---------------------------------------------------

# output fslinfo just to be save
currTxt='FSL INFO for '$fileName':'
echo ' '; echo $currTxt; echo $currTxt | sed 's/./-/g'; echo ' '
fslinfo $(dirname $currFile)'.nii.gz'


# remove dump
#rm '/tmp/tmp.txt'

echo ' '
