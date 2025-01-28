#!/bin/bash

# Generates and submites one normalization script per subject
# @Martin E. Johansson, 28/01/2025

BIDSDIR="/project/3022026.01/pep/bids"
QSIPREPDIR="${BIDSDIR}/derivatives/qsiprep"
WDIR="/project/3022026.01/wd/qsiprep/tmpscripts"
NORM="/home/sysneu/marjoh/scripts/qsimeasure/normalize2.sh"
TEMPLATE="HCP1065_MD" #HCP1065_FA or HCP1065_MD or FMRIB58
SCRIPTPREPEND=""
LIST_SUBJECTS=( `find ${QSIPREPDIR}/sub-POMU* -maxdepth 0 -type d -printf "%f\n"` )
LEN=${#LIST_SUBJECTS[@]}
for (( i=0; i<${LEN}; i++ )); do 
	echo "Processing ${LIST_SUBJECTS[i]} $((${i}+1))/${LEN}"
	qscript="${WDIR}/job_${i}_qsub.sh"
	rm -f $qscript
	exe="${NORM} -d ${BIDSDIR} -p ${LIST_SUBJECTS[i]} -t ${TEMPLATE}"
	echo -e "$SCRIPTPREPEND" > $qscript
	echo -e "$exe" >> $qscript
	echo -e "$SCRIPTPREPEND" >> $qscript
	id=`qsub -o ${QSIPREPDIR}/logs -e ${QSIPREPDIR}/logs -N qnorm-${TEMPLATE}_${LIST_SUBJECTS[i]} -l 'nodes=1:ppn=1,walltime=03:00:00,mem=4gb' $qscript | awk '{print $1}'`
	sleep 0.5
	rm $qscript
done
