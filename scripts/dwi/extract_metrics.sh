#!/bin/bash

# Extracts stats from masks of the substantia nigra
# @Martin E. Johansson, 28/01/2025

usage (){

	cat <<USAGE
	
	Usage: 
	
	`basename $0` -d -i -m
	
	Description: 

	Extract summary statistics from regions-of-interest

	Compulsory arguments: 
	
	-d: Data directory (output of assemble_images.sh)
	
	-i: Image type
	
	-m: Index mask

USAGE

	exit 1

}

# Provide help
[ "$1" == "" ] && usage >&2
[ "$1" == "-h" ] && usage >&2
[ "$1" == "--help" ] && usage >&2

# Get command-line options
while getopts ":d:i:m:" OPT; do

	case "${OPT}" in 
		d)
			echo ">>> -d ${OPTARG}"
			optD=${OPTARG}
		;;
		i)
			echo ">>> -i ${OPTARG}"
			optI=${OPTARG}
		;;
		m)
			echo ">>> -m ${OPTARG}"
			optM=${OPTARG}
		;;
		\?)
			echo ">>> Error: Invalid option -${OPTARG}."
			usage >&2
		;;
		:)
			echo ">>>> Error: Option -${OPTARG} requires an argument."
			usage >&2
		;;
	esac

done

# Set up environment
export FSLDIR=/opt/fsl/6.0.5
.  ${FSLDIR}/etc/fslconf/fsl.sh
DATADIR=${optD}
IMG=${optI}
MASK=${optM}
mkdir -p ${DATADIR}/wd_${IMG}
cd ${DATADIR}/wd_${IMG}
rm $(pwd)/*

# Bilateral masks
${FSLDIR}/bin/fslmaths ${MASK} -thr 1 -uthr 2 -bin bi_aSN
${FSLDIR}/bin/fslmaths ${MASK} -thr 3 -uthr 4 -bin bi_pSN
# Unilateral masks
${FSLDIR}/bin/fslmaths ${MASK} -thr 1 -uthr 1 -bin R_aSN
${FSLDIR}/bin/fslmaths ${MASK} -thr 2 -uthr 2 -bin L_aSN
${FSLDIR}/bin/fslmaths ${MASK} -thr 3 -uthr 3 -bin R_pSN
${FSLDIR}/bin/fslmaths ${MASK} -thr 4 -uthr 4 -bin L_pSN

MASKLIST=(bi_aSN bi_pSN R_aSN L_aSN R_pSN L_pSN)

# Extract stats for each mask
for m in ${MASKLIST[@]}; do

	echo ">>> MASK: ${m}"
	# Extract stats
	${FSLDIR}/bin/fslstats -t ${DATADIR}/${IMG}_norm_ALL.nii.gz -k ${m}.nii.gz -m | tr -d "[:blank:]" > avg_${m}.txt
	${FSLDIR}/bin/fslstats -t ${DATADIR}/${IMG}_norm_ALL.nii.gz -k ${m}.nii.gz -s | tr -d "[:blank:]" > sd_${m}.txt
	echo ">>> done"

done

# Combine to single file
for i in avg sd; do

  echo "IMG,aSN_${i},pSN_${i},R_aSN_${i},L_aSN_${i},R_pSN_${i},L_pSN_${i}" > ${DATADIR}/${IMG}_stats_${i}.csv
  paste -d , ../${IMG}_list_ALL.txt ${i}_bi_aSN.txt ${i}_bi_pSN.txt ${i}_R_aSN.txt ${i}_L_aSN.txt ${i}_R_pSN.txt ${i}_L_pSN.txt >> ${DATADIR}/${IMG}_stats_${i}.csv

done

#rm -r wd_${IMG}





