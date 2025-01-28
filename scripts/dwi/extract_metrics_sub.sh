#!/bin/bash

# Generates and submites one extraction script per subject
# @Martin E. Johansson, 28/01/2025

SCRIPT="/home/sysneu/marjoh/scripts/qsimeasure/extract_metrics.sh"
SCRIPTPREPEND=""
FWDIR="/project/3024006.02/Analyses/MJF_FreeWater"
DATADIR=${FWDIR}/data
ROIDIR=${FWDIR}/ROIs
WDIR=${FWDIR}/tmpscripts
mkdir -p ${WDIR}
ARG_D=("${DATADIR}/n2_pasternak_fw")
ARG_I=("FW")
ARG_M=("${ROIDIR}/n2_ROIs_HCP1065_1mm.nii.gz")

if [ "${#ARG_D[@]}" -ne "${#ARG_I[@]}" ]; then
  echo "Number or arguments in D not identical to number of arguments in I"
  exit 0
fi

len=${#ARG_D[@]}
for(( i=0; i<${len}; i++ )); do
 
	qscript="${WDIR}/job_${i}_qsub.sh"
	rm -f ${qscript}
	exe="${SCRIPT} -d ${ARG_D[i]} -i ${ARG_I[i]} -m ${ARG_M[0]}"
	echo -e "${SCRIPTPREPEND}" > ${qscript}
	echo -e "${exe}" >> ${qscript}
	echo -e "${SCRIPTPREPEND}" >> ${qscript}
	echo "Submitting to cluster: ex_met_${i}"
	id=`qsub -o ${FWDIR}/logs -e ${FWDIR}/logs -N ex_met_${i} -l 'nodes=1:ppn=1,walltime=10:00:00,mem=60gb' ${qscript} | awk '{print $1}'`
	sleep 0.5
	rm $qscript

done
