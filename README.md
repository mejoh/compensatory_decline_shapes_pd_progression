# compensatory_decline_shapes_pd_progression (under construction)
This repository will contain all analysis code used in "Parkinson’s disease progression is shaped by longitudinal changes in cerebral compensation" - Johansson et al. in preparation.

# Repository folder structure
|_ Data
|_ ROIs\
|__ Johansson2024_BRAIN...\
|__ n2_ROIs...\
|_ scripts\
|__ dwi\
|___ dti\
|__ freesurfer\
|__ tb_fMRI\
|___ 1st_level\
|___ group_level\
|____ clinical_correlations\
|____ group_comparisons\
|__ longitudinal...rRmd\
|_ templates\
|__ 50hc50pd_b0-avg\
|__ FMRIB58_FA\
|__ HCP1065_FA\
|__ HCP1065_MD

# Data supporting figures 1-5
All data used to generate plots can be found in the following link: https://surfdrive.surf.nl/files/index.php/s/O3ygV8gjUjx7oca. For Figures 3-4, statistial derivatives from imaging analyses are also included.

# Clinical characteristics and demographics
**Directory**: /scripts/`longitudinal_clinical_and_task-based_analysis.Rmd`
- Demographics
- Clinical scores
- Symptom progression
  1. Longitudinal mixed effects modelling
  2. Co-variance with cognition and medication

# Task performance
**Directory**: /scripts/`longitudinal_clinical_and_task-based_analysis.Rmd`
- Response times
  1. Longitudinal mixed effects modelling
  2. Clinical correlations
- Additional behavioral metrics: accuracy, misses, button variability, switching variability

# MRI

## BIDSification
Example code:\
`module load bidscoin/4.0.0`\
`source activate /opt/bidscoin`\
`cd /project/directory`\
`bidsmapper raw bids`\
`bidseditor bids`\
`bidscoiner raw bids`\

Resulting file structure:\
|_ bids directory\
|__ sub-0X\
|___ ses-0Y\
|____ anat\
|_____ sub-0X_ses-0Y_acq-MPRAGE_T1w.json\
|_____ sub-0X_ses-0Y_acq-MPRAGE_T1w.nii.gz\
|____ func\
|_____ sub-0X_ses-0Y_task-motor_acq-MB6_bold.json\
|_____ sub-0X_ses-0Y_task-motor_acq-MB6_bold.nii.gz\
|____ dwi\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.bval\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.bvec\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.json\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_dwi.nii.gz\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_sbref.json\
|_____ sub-0X_ses-0Y_acq-MB3_dir-AP_sbref.nii.gz\
|____ fmap\
|_____ sub-0X_ses-0Y_acq-MB3_dir-PA_epi.json\
|_____ sub-0X_ses-0Y_acq-MB3_dir-PA_epi.nii.gz\
|____ beh\
|_____ sub-0X_ses-0Y_task-motor_acq-MB6_events.json\
|_____ sub-0X_ses-0Y_task-motor_acq-MB6_events.tsv

## Task-based functional MRI

### Preprocessing
Example code for fMRIPREP:\
`module load fmriprep/23.0.2`\
`cd /project/directory/bids`\
`/opt/conda/bin/fmriprep /project/directory/bids /project/directory/bids/derivatives/fmriprep_v23.0.2/motor participant -w /scratch/marjoh/50961740.dccn-l029.dccn.nl/sub-ID01 --participant-label ID01 --skip-bids-validation --fs-license-file /opt_host/fmriprep/license.txt --mem_mb 37500 --omp-nthreads 4 --nthreads 4 --task-id motor --use-aroma --echo-idx 1 --ignore fieldmaps flair --output-spaces MNI152NLin6Asym --longitudinal --skip_bids_validation`

### First-level
**Directory**: /scripts/tb_fMRI/1st_level\
|_ `rewrite_fmriprep_confounds_aroma2.m` correlates task regressors against ICA-AROMA noise components and relabels those that pass a certain threshold (5% explained variance) to non-noise.\
|__ `generate_task_regressors.m` generates regressors from task events, defined according to `extract_onsets_and_duration_pm.m`.
|_ `motor_1stlevel.m` carries out the first-level analysis.\
|__ `extract_onsets_and_duration_pm.m` extract onsets and durations from task performance data, and generates parametric modulations of them.\
|__ `non_gm_covariates_fmriprep.m` extracts confound timeseries from fMRIPREP output and inserts them as covariates in the first-level analysis.\
`motor_copycontrasts.m` prepares first-level contrasts for group-level analysis. Left-sided responders are flipped horizontally so that the responding side is the same across participants.
`ZipOrUnzip.m` utility function used to compress unused beta images from the 1st-level analysis

### Regions-of-interest for group-level analyses
**Directory**: /ROIs\
`Johansson2024_BRAIN_ROIs.sh` describes how the main region-of-interest `Johansson2024_BRAIN_ROIs.nii` was constructed from the results of [Johansson et al. 2024](https://doi.org/10.1093/brain/awad325).

### Statistical analysis: Longitudinal mixed effects modelling (AFNI, 3dLME)
**Directory**: /scripts/tb_fMRI/group_level/group_comparisons\
`dataTable_3dLMEr_multiple.R` and `dataTable_3dLMEr_single.R` will prepare tables to be used as input for 3dLME.\
`3dLME.sh` carries out the mixed effects modelling.\
`3dLME_ClusterizeResid.sh` generates tables that determine the cluster-level threshold of significance.\
`ExtractClusters.sh` and `ExtractClusters_runcode.sh` identifies significant clusters.\
`ExtractBetas.m` and `ExtractBetas_runcode.m` extracts values from significant clusters.\
`longitudinal_clinical_and_task-based_analysis.Rmd` visualizes results in graphs.

### Statistical analysis: Clinical correlations (FSL, randomise)
**Directory**: /scripts/tb_fMRI/group_level/clinical_correlations\
`motor_2ndlevel_Differencing.m` takes the delta between visits (follow-up - baseline) for each first-level contrast of interest.\
`fsl_randomise_covars.R` generates files needed to perform by-session and complete-case correlation analyses with clinical scores. Relies on `retrieve_resphand.R` to find the responding hand of participants.\
`fsl_add_regressors_to_covs.m` adds indices of basal ganglia dysfunction and posterior substantia nigra free water to covariate files.\
`fsl_randomise_imgs.sh` concatenates images and produces scripts for running randomise-parallel.\
`fsl_randomise_jobsub.sh` submites randomise-parallel scripts to the cluster.\
`fsl_extract_stats.sh` and `fsl_extract_stats_loop.sh` extracts stats and produces visualization-friendly variants of statistical images from randomise.\
`longitudinal_clinical_and_task-based_analysis.Rmd` visualizes results in graphs.

## Diffusion-weighted MRI

### Preprocessing

#### QSIprep
Example code for QSIprep:\
`module load qsiprep/0.19.0`\
`cd /project/directory/bids`\
`/usr/local/miniconda/bin/qsiprep /project/directory/bids /project/directory/bids/derivatives participant --output-resolution 2 -w /scratch/marjoh/50614976.dccn-l029.dccn.nl/sub-0X --participant-label 0X --skip-bids-validation --fs-license-file /opt_host/fmriprep/license.txt --mem_mb 30000 --omp-nthreads 1 --nthreads 1 --skip_bids_validation --dwi-only --denoise-method dwidenoise --unringing-method mrdegibbs --prefer_dedicated_fmaps --pepolar-method TOPUP --eddy-config /project/directory/bids/derivatives/qsiprep/eddy_params.json --write-graph`

#### FreeSurfer longitudinal pipeline
**Directory**: /scripts/freesurfer\
`s0_copy_T1.sh` prepares T1w anatomicals for recon-all.\
|_ `fs_submitJobs.sh` provides utility for submitting steps 1-3 above to a torque cluster.
|__ `s1_fs_cross_processSubject.sh` performs recon-all on all T1w images.\
|__ `s2_fs_base_processSubject.sh` creates base output that occupies the halfway space between baseline and follow-up measurements.\
|__ `s3_fs_long_processSubject.sh` generates recon-all outputs that are unbiased with respect to time.\

### Diffusion metrics
**Directory**: /scripts/dwi/dti\
|_ `qsimeasure.py` is a utility function for generating metrics from QSIprep-processed DWI data.\
|__ `dipy_b0.py` uses DIpy to generate b0 images.\
|__ `dipy_fw.py` uses DIpy to generate a variety of tensors with DIpy and FSL implementations.\
|__ `amico_noddi.py` generates NODDI metrics. Currently not used, but included here for convenience if it becomes relevant at a later stage.

### Study-specific templates
**Directory**: /templates and /scripts/dwi\
`ANTs_generate_template.sh` IN PROGRESS\
- **FA**: `HCP1065_FA` and `FMRIB58_FA` directories contain 1mm and 2mm resolution templates in MNI-space based on FA images of 50 healthy controls and 50 patients (both baseline and follow-up), created using `antsMultivariateTemplateConstruction.sh`. FSL-standard templates in HCP1065- and FMRIB58-space were used as targets.\
- **MD**: `HCP1065_MD`. Same as FA, except the target image in MNI space was an MD template.\
- **b0**: `50hc50pd_b0-avg`. This template was formed by taking the average across baseline and follow-up b0 images from the same 50 healthy controls and 50 patients that were included in the FA and MD template construction.

### Normalization of diffusion metrics
**Directory**: /scripts/dwi\
`normalize_sub.sh` and `normalize2.sh` will normalize diffusion metrics according to the following steps: 1) create an unbiased T1w template, 2) boundary-based DWI>T1w transformation, 3) non-linear transformation from DWI>T1w>MNI. normalize2.sh will additionally project selected metrics onto the base (i.e. halfway) cortical surfaces generated by the FreeSurfer longitudinal pipeline. 

### Substantia nigra free water
**Directory**: /scripts/dwi\
`n2_ROIs_HCP1065_1mm.nii.gz` is a region-of-interest that was drawn on the `50hc50pd_b0-avg` template using FSLeyes, following conventions explained in [Archer et al. 2019](https://doi.org/10.1016/S2589-7500(19)30105-0).\
`n2_ROIs_HCP1065_1mm_labels.txt` details the coordinates and labels of the SN roi.\
`extract_metrics_sub.sh` and `extract_metrics.sh` extracts free water values from the SN mask.

### Statistical analysis
**Directory**: /scripts/`longitudinal_structural_analysis.Rmd`
- Substantia nigra free water
  1. Longitudinal mixed effects modelling and clinical correlations
  2. Clinical correlations
- Surface-based mean diffusivity
  1. Longitudinal mixed effects modelling and clinical correlations
  2. Clinical correlations
  3. `plot_surface_md.R` visualizes cortical MD

