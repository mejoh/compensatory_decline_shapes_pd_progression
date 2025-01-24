# compensatory_decline_shapes_pd_progression
 Personalized Parkinson Project - Longitudinal analysis of action selection-related brain activity and its association with clinical scores

# Clinical

## Demographics
## Clinical scores
## Symptom progression
### Longitudinal mixed effects modelling
### Co-variance with cognition and medication

# Behavioral

## Response times
### Longitudinal mixed effects modelling
### Clinical correlations
## Other metrics

# MRI

## BIDSification
Example code:
`module load bidscoin/4.0.0`
`source activate /opt/bidscoin`
`cd /project/directory`
`bidsmapper raw bids`
`bidseditor bids`
`bidscoiner raw bids`
Resulting file structure:
- bids directory
-- sub-0X
--- ses-0Y
---- anat
----- sub-0X_ses-0Y_acq-MPRAGE_T1w.json
----- sub-0X_ses-0Y_acq-MPRAGE_T1w.nii.gz
---- func
----- sub-0X_ses-0Y_task-motor_acq-MB6_bold.json
----- sub-0X_ses-0Y_task-motor_acq-MB6_bold.nii.gz
---- dwi
----- sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.bval
----- sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.bvec
----- sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.json
----- sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.nii.gz
----- sub-0X_ses-0Y_acq-MB3_dir-AP_sbref.json
----- sub-0X_ses-0Y_acq-MB3_dir-AP_sbref.nii.gz
---- fmap
----- sub-0X_ses-0Y_acq-MB3_dir-PA_epi.json
----- sub-0X_ses-0Y_acq-MB3_dir-PA_epi.nii.gz
---- beh
----- sub-0X_ses-0Y_task-motor_acq-MB6_events.json
----- sub-0X_ses-0Y_task-motor_acq-MB6_events.tsv

## Task-based functional MRI
### Preprocessing
Example code for fMRIPREP:
`module load fmriprep/23.0.2`
`cd /project/directory/bids`
`/opt/conda/bin/fmriprep /project/directory/bids /project/directory/bids/derivatives/fmriprep_v23.0.2/motor participant -w /scratch/marjoh/50961740.dccn-l029.dccn.nl/sub-ID01 --participant-label ID01 --skip-bids-validation --fs-license-file /opt_host/fmriprep/license.txt --mem_mb 37500 --omp-nthreads 4 --nthreads 4 --task-id motor --use-aroma --echo-idx 1 --ignore fieldmaps flair --output-spaces MNI152NLin6Asym --longitudinal --skip_bids_validation`
### First-level
Directory: M:\scripts\compensatory_decline_shapes_pd_progression\scripts\func\1st_level
`rewrite_fmriprep_confounds_aroma2.m` correlates task regressors against ICA-AROMA noise components and relabels those that pass a certain threshold (5% explained variance) to non-noise.
`motor_1stlevel.m` carries out the first-level analysis.
`extract_onsets_and_duration_pm.m` extract onsets and durations from task performance data, and generates parametric modulations of them.
`non_gm_covariates_fmriprep.m` extracts confound timeseries from fMRIPREP output and inserts them as covariates in the first-level analysis.
`motor_copycontrasts.m` prepares first-level contrasts for group-level analysis. Left-sided responders are flipped horizontally so that the responding side is the same across participants.
### Longitudinal mixed effects modelling (AFNI, 3dLME)
Directory: M:\scripts\compensatory_decline_shapes_pd_progression\scripts\func\group_level\group_comparisons
`dataTable_3dLMEr_multiple.R` and `dataTable_3dLMEr_single.R` will prepare tables to be used as input for 3dLME.
`3dLME.sh` carries out the mixed effects modelling.
`3dLME_ClusterizeResid.sh` generates tables that determine the cluster-level threshold of significance.
`ExtractClusters.sh` and `ExtractClusters_runcode.sh` identifies significant clusters.
`ExtractBetas.m` and `ExtractBetas_runcode.m` extracts values from significant clusters.
### Clinical correlations (FSL, randomise)
Directory: M:\scripts\compensatory_decline_shapes_pd_progression\scripts\func\group_level\clinical_correlations
`motor_long_roi.sh` generates a mask of BG dysfunction and cortical compensation based on previous findings.
`motor_2ndlevel_Differencing.m` takes the delta between visits (follow-up - baseline) for each first-level contrast of interest.
`fsl_randomise_covars.R`
`fsl_add_regressors_to_covs.m`
`fsl_randomise_imgs.sh`
`fsl_randomise_jobsub.sh`
`fsl_extract_stats.sh`
`fsl_extract_stats_loop.sh`

## Diffusion-weighted MRI
### Preprocessing
Example code for QSIprep:
`module load qsiprep/0.19.0`
`cd /project/directory/bids`
`/usr/local/miniconda/bin/qsiprep /project/directory/bids /project/directory/bids/derivatives participant --output-resolution 2 -w /scratch/marjoh/50614976.dccn-l029.dccn.nl/sub-0X --participant-label 0X --skip-bids-validation --fs-license-file /opt_host/fmriprep/license.txt --mem_mb 30000 --omp-nthreads 1 --nthreads 1 --skip_bids_validation --dwi-only --denoise-method dwidenoise --unringing-method mrdegibbs --prefer_dedicated_fmaps --pepolar-method TOPUP --eddy-config /project/directory/bids/derivatives/qsiprep/eddy_params.json --write-graph`
### Study-specific templates
- b0
- FA
- MD
### Posterior substantia nigra free water
#### Free water mapping and mask drawing
#### Longitudinal mixed effects modelling
#### Clinical correlations
### Surface-based cortical mean diffusivity
#### Mean diffusivity mapping and surface projection
#### Longitudinal mixed effects modelling
#### Clinical correlations
