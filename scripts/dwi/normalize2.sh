#!/bin/bash

# Normalize DTI metrics to template. Also do surface-based projection if metric is MD.
# @Martin E. Johansson, 28/01/2025

# Usage

usage (){

	cat <<USAGE
	
	Usage:
	
	`basename $0` -d <path> -p <subid> -t <template> <other options>
	
	Description:
	
	Normalize qsimeasure.py output to MNI-space
	
	Compulsory arguments:
	
	-d: BIDS directory
	
	-p: Subject ID
	
	-t: Template (FMRIB58_FA, HCP1065_FA, HCP1065_MD)
	
	Examples:
	
	1. ~/scripts/qsimeasure/normalize2.sh -d /project/3022026.01/pep/bids -p sub-POMUAAF1257055021C21 -t HCP1065_MD
	
	2. ~/scripts/qsimeasure/normalize_sub.sh
	
USAGE

	exit 1

}

# >>> Provide help
[ "$1" == "" ] && usage >&2
[ "$1" == "-h" ] && usage >&2
[ "$1" == "--help" ] && usage >&2

# >>> Get command-line options
while getopts ":d:p:t:" OPT; do
	case "${OPT}" in
		d)
			echo ">>> -d ${OPTARG}"
			optD=${OPTARG}
		;;
		p)
			echo ">>> -p ${OPTARG}"
			optP=${OPTARG}
		;;
		t)
			echo ">>> -t ${OPTARG}"
			optT=${OPTARG}
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
shift $((OPTIND-1))

# >>> Set up environment, directories, and template (adjust as necessary)
export APPTAINER="/opt/apptainer/1.1.5"
export ANTs_IMAGE="/opt/ANTs/2.4.0/ants-2.4.0.simg"
export FREESURFER_HOME="/opt/freesurfer/7.3.2"
export SUBJECTS_DIR="/project/3022026.01/pep/bids/derivatives/freesurfer_v7.3.2/outputs"
export FSLDIR=/opt/fsl/6.0.5
.  ${FSLDIR}/etc/fslconf/fsl.sh
module unload qsiprep # Interferes with the FS license

bidsdir=${optD}
subject=${optP}
template=${optT}
qsiprepdir=${bidsdir}/derivatives/qsiprep
qsiprep_sub=${qsiprepdir}/${subject}
fsdir=${bidsdir}/derivatives/freesurfer_v7.3.2/outputs
fsdir_sub=${fsdir}/${subject}
mkdir -p ${qsiprep_sub}/wd
mkdir -p ${qsiprep_sub}/reg

echo ${optT}
# Check mandatory arguments
if [ ! "$bidsdir" ] || [ ! "$subject" ] || [ ! "$template" ]; then
  echo ">>> Error: arguments -d, -p, and -t must be provided"
  usage >&2
fi
# Set template
if [ ${template} == "HCP1065_FA" ]; then
	echo ">>> Using HCP1065_FA_1mm (study-specific) as target in normalizations"
	# MNI_img: used to estimate normalization
	MNI_img="/project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_template0_fsl.nii.gz"
	# MNI_img_downsampled: used to visualization purposes (template2mni normalization)
	MNI_img_downsampled="/project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_template0_fsl.nii.gz"
	# MNI_mask: used to define the voxel-size of the output image
	MNI_mask="/project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_template0_fsl_mask_ero.nii.gz"
	nprepend="n2"
	IMGTYPE="FA"
	SURFACE_METRICS=0
elif [ ${template} == "HCP1065_MD" ]; then
	echo ">>> Using HCP1065_MD_1mm (study-specific) as target in normalizations"
	MNI_img="/project/3024006.02/templates/template_50HC50PD/HCP1065_MD_template/T_template0_fsl.nii.gz"
	MNI_img_downsampled="/project/3024006.02/templates/template_50HC50PD/HCP1065_MD_template/T_template0_fsl_2mm.nii.gz"
	MNI_mask="/project/3024006.02/templates/template_50HC50PD/HCP1065_MD_template/T_template0_fsl_mask_ero_2mm.nii.gz"
	nprepend="n3"
	IMGTYPE="MD"
	SURFACE_METRICS=1
elif [ ${template} == "FMRIB58_FA" ]; then
	echo ">>> Using FMRIB58_FA_1mm (study-specific) as target in normalizations"
	MNI_img="/project/3024006.02/templates/template_50HC50PD/FMRIB58_FA_template/T_template0.nii.gz"
	MNI_img_downsampled="/project/3024006.02/templates/template_50HC50PD/FMRIB58_FA_template/T_template0_fsl_2mm.nii.gz"
	MNI_mask="/project/3024006.02/templates/template_50HC50PD/FMRIB58_FA_template/T_template0_fsl_mask_ero_2mm.nii.gz"
	nprepend="n1"
	IMGTYPE="FA"
	SURFACE_METRICS=0
else
  echo ">>> Error: Template option invalid"
  usage >&2
fi
# Check QSIprep output
if [ ! -f "${qsiprepdir}/${subject}.html" ]; then
	echo ">>> Error: QSIprep output missing"
	exit 1
fi
# Check if already processed (need a better check condition than this...)
# norms=( $(ls ${qsiprep_sub}/ses*/metrics/*/${nprepend}*.nii.gz) )
# len=${#norms}
# if [ ${len} -gt 0 ]; then
  # echo ">>> Subject already has normalized data, skipping..."
  # exit 0
# fi

# >>> Build within-subject anatomical template
# List images
echo ">>> Finding images for template building..."
IMG_LIST=( $(ls ${qsiprep_sub}/ses*/metrics/dipy_fw/sub-*fsl_${IMGTYPE}.nii.gz) )
len=${#IMG_LIST[@]}
if [ ${#IMG_LIST[@]} -lt 1 ]; then
 echo ">>> Error: No FA images"
 exit 1
fi
# Template creation
echo ">>> Creating template"
if [ ${len} -gt 1 ]; then
echo ">>> Multiple images found, running mri_robust_template"
${FREESURFER_HOME}/bin/mri_robust_template \
 --satit \
 --mov `echo ${IMG_LIST[@]}` \
 --inittp 1 \
 --iscale \
 --template ${qsiprep_sub}/wd/template.nii.gz \
 --subsample 200
elif [ ${len} -eq 1 ]; then
  echo ">>> Only 1 image found, copying"
  cp ${IMG_LIST[0]} ${qsiprep_sub}/wd/template.nii.gz
else
  echo ">>> ERROR: Number of images is inappropriate"
	exit 1
fi
${FSLDIR}/bin/fslreorient2std ${qsiprep_sub}/wd/template.nii.gz ${qsiprep_sub}/wd/template.nii.gz

# >>> Estimate template-to-MNI transformation
echo ">>> Estimating transform: template to MNI"
template2mni=${qsiprep_sub}/reg/${nprepend}_ants_template_to_mniComposite.h5
if [ ! -f ${template2mni} ]; then
 echo ">>> No template2mni transform found, estimating..."
 cmd="antsRegistration --collapse-output-transforms 1 --dimensionality 3 --float 1 --initial-moving-transform [ ${MNI_img}, ${qsiprep_sub}/wd/template.nii.gz, 1 ] --initialize-transforms-per-stage 0 --interpolation LanczosWindowedSinc --output [ ${qsiprep_sub}/reg/${nprepend}_ants_template_to_mni, ${qsiprep_sub}/wd/ants_template_to_mni_Warped.nii.gz ] --transform Rigid[ 0.1 ] --metric Mattes[ ${MNI_img}, ${qsiprep_sub}/wd/template.nii.gz, 1, 32, Regular, 0.25 ] --convergence [ 1000x500x250x100, 1e-06, 10 ] --smoothing-sigmas 3x2x1x0vox --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform Affine[ 0.1 ] --metric Mattes[ ${MNI_img}, ${qsiprep_sub}/wd/template.nii.gz, 1, 32, Regular, 0.25 ] --convergence [ 1000x500x250x100, 1e-06, 20 ] --smoothing-sigmas 3x2x1x0vox --shrink-factors 8x4x2x1 --use-histogram-matching 1 --transform SyN[ 0.1, 3.0, 0.0 ] --metric CC[ ${MNI_img}, ${qsiprep_sub}/wd/template.nii.gz, 1, 4, None, 1 ] --convergence [ 100x70x50x20, 1e-06, 10 ] --smoothing-sigmas 3.0x2.0x1.0x0.0vox --shrink-factors 8x4x2x1 --use-histogram-matching 1 --winsorize-image-intensities [ 0.005, 0.995 ] --write-composite-transform 1 -v"
 ${APPTAINER}/bin/apptainer run ${ANTs_IMAGE} ${cmd}
else
 echo ">>> Previously estimated template2mni transformation found, utilizing this for normalizations"
fi

# >>> Estimate IMG-to-template transformation
for (( i=0; i<${len}; i++ )); do
 echo ">>> Estimating transform: IMG to template $((${i}+1))"
 ${FSLDIR}/bin/fslreorient2std ${IMG_LIST[i]} ${qsiprep_sub}/wd/i${i}_img.nii.gz
 cmd="antsRegistration --collapse-output-transforms 1 --dimensionality 3 --float 1 --initial-moving-transform [ ${qsiprep_sub}/wd/template.nii.gz, ${qsiprep_sub}/wd/i${i}_img.nii.gz, 1 ] --initialize-transforms-per-stage 0 --interpolation LanczosWindowedSinc --output [ ${qsiprep_sub}/wd/i${i}_img_to_template, ${qsiprep_sub}/wd/i${i}_img_to_template_Rigid.nii.gz ] --transform Rigid[ 0.1 ] --metric Mattes[ ${qsiprep_sub}/wd/template.nii.gz, ${qsiprep_sub}/wd/i${i}_img.nii.gz, 1, 32, Regular, 0.25 ] --convergence [ 1000x500x250x100, 1e-06, 10 ] --smoothing-sigmas 3x2x1x0vox --shrink-factors 8x4x2x1 --use-histogram-matching 1 --winsorize-image-intensities [ 0.005, 0.995 ] --write-composite-transform 1 -v"
 ${APPTAINER}/bin/apptainer run ${ANTs_IMAGE} ${cmd}
 
 # Normalize metric (for quality control purposes only)
 cmd="antsApplyTransforms --default-value 0 --float 1 --input ${qsiprep_sub}/wd/i${i}_img.nii.gz --interpolation LanczosWindowedSinc --output ${qsiprep_sub}/wd/i${i}_img_to_mni_Warped.nii.gz --reference-image ${MNI_mask} --transform ${template2mni} --transform ${qsiprep_sub}/wd/i*_img_to_templateComposite.h5 --transform identity"
 ${APPTAINER}/bin/apptainer run ${ANTs_IMAGE} ${cmd}
done
img2template=( $(ls ${qsiprep_sub}/wd/i*_img_to_templateComposite.h5) )

# >>> Loop over sessions (unpack tensor, normalize, qc, freesurfer surface-based metrics)
sessions=( $(ls -d ${qsiprep_sub}/ses*) )
len=${#sessions[@]}
for (( i=0; i<${len}; i++ )); do

 echo ">>> Applying transformation: IMG to MNI, session $((${i}+1))"
 
 # Unpack Pasternak's tensors
 tensor=( $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*TensorFWCorrected.nii.gz) )
 if [ -f  ${tensor} ]; then
	${FSLDIR}/bin/fslmaths ${tensor} -tensor_decomp `echo ${tensor} | sed 's/.nii.gz/_dcmp/'`
 fi
 tensor=( $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*TensorDTINoNeg.nii.gz) )
 if [ -f  ${tensor} ]; then
	${FSLDIR}/bin/fslmaths ${tensor} -tensor_decomp `echo ${tensor} | sed 's/.nii.gz/_dcmp/'`
 fi
 
 # Mask
 ${FSLDIR}/bin/fslreorient2std ${sessions[i]}/dwi/*desc-brain_mask.nii.gz ${qsiprep_sub}/wd/mask.nii.gz
 
 # DTI-to-T1w registration (FreeSurfer)
 if [ ${SURFACE_METRICS} -eq 1 ]; then 
	B0IMG=( $(ls ${sessions[i]}/metrics/dipy_b0/sub-*dipy-b0mean.nii.gz) )
	${FSLDIR}/bin/fslreorient2std ${B0IMG} ${qsiprep_sub}/wd/i${i}_b0.nii.gz
	${FREESURFER_HOME}/bin/bbregister --s ${subject} --mov ${qsiprep_sub}/wd/i${i}_b0.nii.gz --o ${qsiprep_sub}/wd/i${i}_b0_bbreg.nii.gz --init-fsl --reg ${qsiprep_sub}/wd/i${i}_fsregister.dat --lta ${qsiprep_sub}/wd/i${i}_fsregister.lta --dti
 fi
 
 if [ ${template} == "HCP1065_MD" ]; then
	metrics=( $(ls ${sessions[i]}/metrics/dipy_fw/sub-*_fsl_MD.nii.gz) $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*_TensorFWCorrected_dcmp_MD.nii.gz) $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*_TensorDTINoNeg_dcmp_MD.nii.gz) $(ls ${sessions[i]}/metrics/dipy_fw/sub-*_dipy-MDc.nii.gz)  $(ls ${sessions[i]}/metrics/dipy_fw/sub-*_dipy-MD.nii.gz) $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*_FW.nii.gz) )
 else
	metrics=( $(ls ${sessions[i]}/metrics/pasternak_fw/sub-*_FW.nii.gz) $(ls ${sessions[i]}/metrics/dipy_fw/sub-*_dipy-FW.nii.gz) )
 fi
 
 echo ${metrics[@]}
 lan=${#metrics[@]}
 for (( j=0; j<${lan}; j++ )); do
 
  # Normalize metric
  in=${metrics[j]}
  dn=`dirname ${in}`
  bn=`basename ${in}`
	on=${dn}/${nprepend}_${bn}
	
	${FSLDIR}/bin/fslreorient2std ${in} ${qsiprep_sub}/wd/metric.nii.gz
	${FSLDIR}/bin/fslmaths ${qsiprep_sub}/wd/metric.nii.gz -mas ${qsiprep_sub}/wd/mask.nii.gz ${qsiprep_sub}/wd/metric.nii.gz
	echo ">>> Applying transform: ${bn} to MNI"
	cmd="antsApplyTransforms --default-value 0 --float 1 --input ${qsiprep_sub}/wd/metric.nii.gz --interpolation LanczosWindowedSinc --output ${on} --reference-image ${MNI_mask} --transform ${template2mni} --transform ${img2template[i]} --transform identity"
  ${APPTAINER}/bin/apptainer run ${ANTs_IMAGE} ${cmd}
	
	# EXTRA: Surface-based DTI metrics
	
	if [ ${SURFACE_METRICS} -eq 1 ]; then 
   echo ">>>"
   echo ">>> Generating surface-based DTI metrics"
 
   for hemi in "lh" "rh"; do
	 
	   metric_name=`basename -- "${in}" .nii.gz`
	 
     echo ">>> Hemisphere: ${hemi}"
     # Generate graymid surfaces
     if [ ! -f ${fsdir_sub}/surf/${hemi}.graymid ]; then
       echo ">>> Generating graymid surfaces"
       ${FREESURFER_HOME}/bin/mris_expand -thickness ${fsdir_sub}/surf/${hemi}.white 0.5 ${fsdir_sub}/surf/${hemi}.graymid
     fi

     # Multiply input image by a constant, necessary to ensure that MD is projected properly
     ${FSLDIR}/bin/fslmaths ${qsiprep_sub}/wd/metric.nii.gz -mul 1000 ${qsiprep_sub}/wd/${hemi}_metric.nii.gz
		 
		 # Partial volume correction
		 if [ ! -f ${fsdir_sub}/mri/gtmseg.mgz ]; then
		   # Generate geometric transformation matrix (~1h)
		   ${FREESURFER_HOME}/bin/gtmseg --s ${subject}
		 fi
		 # Run partial volume correction, retaining only voxels that are >30% likely to be grey matter (--mgx .3)
		 ${FREESURFER_HOME}/bin/mri_gtmpvc --i ${qsiprep_sub}/wd/${hemi}_metric.nii.gz --reg ${qsiprep_sub}/wd/i${i}_fsregister.lta --seg ${fsdir_sub}/mri/gtmseg.mgz --default-seg-merge --auto-mask 1 .01 --mgx .3 --o ${qsiprep_sub}/wd/i${i}_gtmpvc.output
		 cp ${qsiprep_sub}/wd/i${i}_gtmpvc.output/mgx.ctxgm.nii.gz ${qsiprep_sub}/wd/${hemi}_metric_PVC.nii.gz

     # Fsaverage space: Vol2Surf, smooth, extract
	   echo ">>> Processing: Fsaverage space"
     ${FREESURFER_HOME}/bin/mris_preproc --iv ${qsiprep_sub}/wd/${hemi}_metric_PVC.nii.gz ${qsiprep_sub}/wd/i${i}_fsregister.dat --target fsaverage --out ${qsiprep_sub}/wd/i${i}_${hemi}_metric_norm_s15.mgz --hemi ${hemi} --projfrac-avg 0.2 0.8 0.1 --cortex-only --fwhm 15
     ${FREESURFER_HOME}/bin/mri_segstats --annot fsaverage ${hemi} aparc --i ${qsiprep_sub}/wd/i${i}_${hemi}_metric_norm_s15.mgz --o ${qsiprep_sub}/wd/i${i}_${hemi}.${metric_name}.norm.stats --surf white --snr

     # Subject space: Vol2Surf, extract
	   echo ">>> Processing: T1w space"
     ${FREESURFER_HOME}/bin/mri_vol2surf --src ${qsiprep_sub}/wd/${hemi}_metric_PVC.nii.gz --out ${qsiprep_sub}/wd/i${i}_${hemi}_metric_T1w.mgz --srcreg ${qsiprep_sub}/wd/i${i}_fsregister.dat --hemi ${hemi} --surf white --projfrac-avg 0.2 0.8 0.1 --cortex --noreshape --trgsubject ${subject}
     ${FREESURFER_HOME}/bin/mri_segstats --annot ${subject} ${hemi} aparc --i ${qsiprep_sub}/wd/i${i}_${hemi}_metric_T1w.mgz --o ${qsiprep_sub}/wd/i${i}_${hemi}.${metric_name}.T1w.stats --surf graymid --snr
		 
		 mkdir -p ${sessions[i]}/metrics/freesurfer
		 cp ${qsiprep_sub}/wd/i${i}_${hemi}_metric_norm_s15.mgz ${sessions[i]}/metrics/freesurfer/${hemi}_metric_norm_s15.mgz
		 cp ${qsiprep_sub}/wd/i${i}_${hemi}.${metric_name}.norm.stats ${sessions[i]}/metrics/freesurfer/${hemi}.${metric_name}.norm.stats
		 cp ${qsiprep_sub}/wd/i${i}_${hemi}_metric_T1w.mgz ${sessions[i]}/metrics/freesurfer/${hemi}_metric_T1w.mgz
		 cp ${qsiprep_sub}/wd/i${i}_${hemi}.${metric_name}.T1w.stats ${sessions[i]}/metrics/freesurfer/${hemi}.${metric_name}.T1w.stats
 
   done
	 
	fi
	
 done
 
 # QC
 # IMG 2 within-subject template
 cd ${qsiprep_sub}/wd
 ${FSLDIR}/bin/slicer i${i}_img_to_template_Rigid.nii.gz template.nii.gz -L -s 2 -z 0.35 sla.png -z 0.36 slb.png -z 0.37 slc.png -z 0.38 sld.png -z 0.39 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
 ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png img_to_template.png
 ${FSLDIR}/bin/slicer template.nii.gz i${i}_img_to_template_Rigid.nii.gz -L -s 2 -z 0.35 sla.png -z 0.36 slb.png -z 0.37 slc.png -z 0.38 sld.png -z 0.39 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
 ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png template_to_img.png
 ${FSLDIR}/bin/pngappend template_to_img.png - img_to_template.png ${qsiprep_sub}/reg/reg_${nprepend}_i${i}_img2template.png; rm -f sl?.png
 # IMG 2 MNI template
 ${FSLDIR}/bin/slicer i${i}_img_to_mni_Warped.nii.gz ${MNI_img_downsampled} -L -s 2 -z 0.35 sla.png -z 0.36 slb.png -z 0.37 slc.png -z 0.38 sld.png -z 0.39 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
 ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png img_to_MNI.png
 ${FSLDIR}/bin/slicer ${MNI_img_downsampled} i${i}_img_to_mni_Warped.nii.gz -L -s 2 -z 0.35 sla.png -z 0.36 slb.png -z 0.37 slc.png -z 0.38 sld.png -z 0.39 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
 ${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png MNI_to_img.png
 ${FSLDIR}/bin/pngappend MNI_to_img.png - img_to_MNI.png ${qsiprep_sub}/reg/reg_${nprepend}_i${i}_img2mni.png; rm -f sl?.png

done

# ${FSLDIR}/bin/immv ${qsiprep_sub}/wd/ants_template_to_mni_Warped.nii.gz ${qsiprep_sub}/reg/${nprepend}_template_to_mni_Warped.nii.gz
cp ${qsiprep_sub}/wd/ants_template_to_mni_Warped.nii.gz ${qsiprep_sub}/reg/${nprepend}_template_to_mni_Warped.nii.gz

# >>> QC
# Within-subject template 2 MNI template
cd ${qsiprep_sub}/reg
${FSLDIR}/bin/slicer ${MNI_img} ${qsiprep_sub}/reg/${nprepend}_template_to_mni_Warped.nii.gz -L -s 2 -z 0.30 sla.png -z 0.31 slb.png -z 0.32 slc.png -z 0.33 sld.png -z 0.34 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png mni_to_template.png
${FSLDIR}/bin/slicer ${qsiprep_sub}/reg/${nprepend}_template_to_mni_Warped.nii.gz ${MNI_img} -L -s 2 -z 0.30 sla.png -z 0.31 slb.png -z 0.32 slc.png -z 0.33 sld.png -z 0.34 sle.png -z 0.45 slf.png -z 0.55 slg.png -z 0.65 slh.png
${FSLDIR}/bin/pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png template_to_mni.png
${FSLDIR}/bin/pngappend template_to_mni.png - mni_to_template.png reg_${nprepend}_template2mni.png; rm -f sl?.png mni_to_template.png; rm template_to_mni.png

# Clean up
rm -r ${qsiprep_sub}/wd

