#!/bin/bash
# ~/scripts/Personalized-Parkinson-Project-Motor/FreeSurfer/fs_submitJobs.sh
# @Martin E. Johansson, 28/01/2025

# Run modules of the FreeSurfer longitudinal pipeline on a torque cluster.
# Note that the fs_*_processSubject.sh scripts may need some adjustment.
# Subjects that already have output will be skipped.

# OPTS
cross=0
base=0
long=1

# Variables that are passed to jobs
version=7.3.2
fs_dir=/project/3022026.01/pep/bids/derivatives/freesurfer_v${version}

# Submit a job for each subject
# -o -e:location of log files
# -N: name of job
# -v: Subject to be processed
# -t: The timepoint to be processed
# -l: Resources allocated to job
# Last line defines the script that each job will submit to the cluster

if [ $cross -eq 1 ]; then

  # Estimated resources: ~6-8h per subject, 2.5gb
	# Note that some subjects can take much longer (+20h)

	cd ${fs_dir}/inputs
	subjects=`ls -d *sub-POMU*`
	timepoints=(t1 t2)
	
	for s in ${subjects[@]}; do 
		for t in ${timepoints[@]}; do
			echo "Processing: ${s}, ${t}"
			qsub \
			-o /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-e /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-N fs_cross_${s}_${t} \
			-v v=${version},fs_dir=${fs_dir},subject=${s},timepoint=${t} \
			-l 'nodes=1:ppn=2,walltime=20:00:00,mem=7gb' \
			~/scripts/Personalized-Parkinson-Project-Motor/FreeSurfer/s1_fs_cross_processSubject.sh
		done
	done
	
fi

if [ $base -eq 1 ]; then

  # Estimated resources: ~6-8h per subject, 2.5gb
	# Note that some subjects can take much longer (+20h)

	cd ${fs_dir}/inputs
	subjects=`ls -d *sub-POMU*`
	
	for s in ${subjects[@]}; do
			echo "Processing: ${s}"
			qsub \
			-o /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-e /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-N fs_base_${s} \
			-v v=${version},fs_dir=${fs_dir},subject=${s} \
			-l 'nodes=1:ppn=2,walltime=20:00:00,mem=4gb' \
			~/scripts/Personalized-Parkinson-Project-Motor/FreeSurfer/s2_fs_base_processSubject.sh
	done
	
fi

if [ $long -eq 1 ]; then

  # Estimated resources: ~3-4h per subject, 2.5gb

	cd ${fs_dir}/inputs
	subjects=`ls -d *sub-POMU*`
	timepoints=(t1 t2)
	
	for s in ${subjects[@]}; do 
		for t in ${timepoints[@]}; do
			echo "Processing: ${s}, ${t}"
			qsub \
			-o /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-e /project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/logs \
			-N fs_long_${s}_${t} \
			-v v=${version},fs_dir=${fs_dir},subject=${s},timepoint=${t} \
			-l 'nodes=1:ppn=2,walltime=20:00:00,mem=4gb' \
			~/scripts/Personalized-Parkinson-Project-Motor/FreeSurfer/s3_fs_long_processSubject.sh
		done
	done

fi



