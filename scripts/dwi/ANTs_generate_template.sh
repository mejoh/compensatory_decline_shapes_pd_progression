#!/bin/bash

# Generate a longitudinally unbiased subject-specific template from 50 patients and 50 controls using ANTs.
# @Martin E. Johansson, 28/01/2025

# Load ANTs
module unload ANTs; module add ANTs/20150225
# Alternative ANTs load
# export APPTAINER="/opt/apptainer/1.1.5"
# export ANTs_IMAGE="/opt/ANTs/2.4.0/ants-2.4.0.simg"

# Specify paths and prepare. Change paths depending on whether processing MD or FA
inputPath=/project/3022026.01/pep/bids/derivatives/qsiprep
outputPath=/project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template
TEMPLATE=/project/3024006.02/templates/fsl/FSL_HCP1065_FA_1mm.nii.gz
mkdir -p $outputPath
cd $outputPath
cp ${TEMPLATE} ${outputPath}/standard.nii.gz

# antsMultivariateTemplateConstruction.sh won't work unless you remove '-q nopreempt' from
# the qsub command prompted by using argument '-c 4'. The script has
# therefore been copied to the project directory and adapted
# https://sourceforge.net/p/advants/discussion/840261/thread/3bccddeb/
	
# Find metrics of interest
metric="fsl_FA"
i_PIT1=( `ls /project/3022026.01/pep/bids/derivatives/qsiprep/sub-*/ses-PITVisit1/metrics/dipy_fw/sub-*${metric}.nii.gz` )
i_PIT2=( `ls /project/3022026.01/pep/bids/derivatives/qsiprep/sub-*/ses-PITVisit2/metrics/dipy_fw/sub-*${metric}.nii.gz` )
i_POM1=( `ls /project/3022026.01/pep/bids/derivatives/qsiprep/sub-*/ses-POMVisit1/metrics/dipy_fw/sub-*${metric}.nii.gz` )
i_POM3=( `ls /project/3022026.01/pep/bids/derivatives/qsiprep/sub-*/ses-POMVisit3/metrics/dipy_fw/sub-*${metric}.nii.gz` )

# Take first 50 participants (pseudonyms are generated randomly)
imgs=`echo "${i_PIT1[@]:0:50} ${i_PIT2[@]:0:50} ${i_POM1[@]:0:50} ${i_POM3[@]:0:50}"`

# Build template
/project/3024006.02/templates/template_50HC50PD/antsMultivariateTemplateConstruction.sh -d 3 -o ${outputPath}/T_ -c 4 -g 0.25 -i 4 -j 2 -k 1 -w 1 -m 100x70x50x10 -n 1 -r 1 -s CC -t GR -y 0 -z ${outputPath}/standard.nii.gz `echo ${imgs[@]}`
	