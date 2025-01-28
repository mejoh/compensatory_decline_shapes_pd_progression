#!/bin/bash
# @Martin E. Johansson, 28/01/2025

#qsub -o /project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/logs -e /project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/logs -N 3dLME_test -l 'nodes=1:ppn=32,walltime=06:00:00,mem=90gb' /home/sysneu/marjoh/scripts/Personalized-Parkinson-Project-Motor/AFNI/3dLME.sh

#ROI=(0); GC=(1); for roi in ${ROI[@]}; do for gc in ${GC[@]}; do qsub -o /project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/logs -e /project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/logs -N 3dLME_${roi}${gc} -v R=${roi},G=${gc} -l 'nodes=1:ppn=32,walltime=07:00:00,mem=85gb' /home/sysneu/marjoh/scripts/Personalized-Parkinson-Project-Motor/AFNI/3dLME.sh; done; done

# R=2
# G=0
# P=1

### OPTIONS ###
ROI=${R}				# 1 = ROI, 0 = Whole-brain
GroupComparison=${G}	# 1 = Group comparison, 0 = Correlation analysis
# Polynomial=${P}			# 1 = Linear, 2 = Quadratic, 3 = Cubic
###

module unload afni; module load afni/2022
module unload R; module load R/4.1.0
module load R-packages/4.1.0
njobs=32

dOutput=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI
con=con_combined

# Define mask
if [ $ROI -eq 1 ]; then

	# ROI analysis
	echo "ROI analysis - Partial"
	dOutput=$dOutput/ROI/Masked_partial
  mask=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/Masks/bi_partial_clincorr_bg_mask_cropped.nii

elif [ $ROI -eq 2 ]; then

	# ROI analysis
	echo "ROI analysis - Full"
	dOutput=$dOutput/ROI/Masked_full
	mask=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/Masks/bi_full_clincorr_bg_mask_cropped.nii

elif [ $ROI -eq 0 ]; then

	# Whole-brain analysis
	echo "Whole-brain analysis"
	dOutput=$dOutput/WholeBrain
	mask=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/Masks/wd/tpl-MNI152NLin6Asym_desc-brain_mask.nii

fi

# Run analysis
if [ $GroupComparison -eq 1 ]; then

	echo "Performing group comparisons"
	
	echo "TimepointNr: Linear"
	dOutput=$dOutput/3dLME_disease
	mkdir -p $dOutput
	dataTable=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/${con}_disease_dataTable2.txt
	cd $dOutput
	cp $mask $(pwd)/mask.nii
	cp $dataTable $(pwd)
	rm ${con}*.BRIK ${con}*.HEAD
	
	/opt/afni/2022/3dLMEr -prefix ${dOutput}/${con}_Group2_x_TimepointNr2_x_Type3 -jobs $njobs \
	-resid ${dOutput}/${con}_Group2_x_TimepointNr2_x_Type3_resid \
	-mask $mask \
	-model '1+Group*TimepointNr*trial_type+Age+Sex+NpsEducYears+RespHandIsDominant+(1+TimepointNr|Subj)' \
	-qVars 'Age,NpsEducYears' \
	-gltCode Group_by_Time_by_Type23gt1 'Group : -1*HC_PIT 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : -1*T0 1*T1' \
	-gltCode HC_by_Time_by_Type23gt1 'Group : 1*HC_PIT trial_type : -1*1c 1*23c TimepointNr : -1*T0 1*T1' \
	-gltCode PD_by_Time_by_Type23gt1 'Group : 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : -1*T0 1*T1' \
	-gltCode Group_by_Time 'Group : -1*HC_PIT 1*PD_POM TimepointNr : -1*T0 1*T1' \
	-gltCode HC_by_Time 'Group : 1*HC_PIT TimepointNr : -1*T0 1*T1' \
	-gltCode PD_by_Time 'Group : 1*PD_POM TimepointNr : -1*T0 1*T1' \
	-gltCode Group_by_Type23gt1 'Group : -1*HC_PIT 1*PD_POM trial_type : -1*1c 1*23c' \
	-gltCode HC_by_Type23gt1 'Group : 1*HC_PIT trial_type : -1*1c 1*23c' \
	-gltCode PD_by_Type23gt1 'Group : 1*PD_POM trial_type : -1*1c 1*23c' \
	-gltCode Group_by_Type23gt1_BA 'Group : -1*HC_PIT 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : 1*T0' \
	-gltCode HC_by_Type23gt1_BA 'Group : 1*HC_PIT trial_type : -1*1c 1*23c TimepointNr : 1*T0' \
	-gltCode PD_by_Type23gt1_BA 'Group : 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : 1*T0' \
	-gltCode Group_by_Type23gt1_FU 'Group : -1*HC_PIT 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : 1*T1' \
	-gltCode HC_by_Type23gt1_FU 'Group : 1*HC_PIT trial_type : -1*1c 1*23c TimepointNr : 1*T1' \
	-gltCode PD_by_Type23gt1_FU 'Group : 1*PD_POM trial_type : -1*1c 1*23c TimepointNr : 1*T1' \
	-gltCode Group 'Group : -1*HC_PIT 1*PD_POM' \
	-gltCode Group_BA 'Group : -1*HC_PIT 1*PD_POM TimepointNr : 1*T0' \
	-gltCode Group_FU 'Group : -1*HC_PIT 1*PD_POM TimepointNr : 1*T1' \
	-gltCode Time 'TimepointNr : -1*T0 1*T1' \
	-gltCode Type123 'trial_type : 0.5*1c 0.5*23c' \
	-gltCode Type123_BA 'trial_type : 0.5*1c 0.5*23c TimepointNr : 1*T0' \
	-gltCode Type123_FU 'trial_type : 0.5*1c 0.5*23c TimepointNr : 1*T1' \
	-gltCode Type23gt1 'trial_type : -1*1c 1*23c' \
	-gltCode Type23gt1_BA 'trial_type : -1*1c 1*23c TimepointNr : 1*T0' \
	-gltCode Type23gt1_FU 'trial_type : -1*1c 1*23c TimepointNr : 1*T1' \
	-dataTable \
	`cat $dataTable`

elif [ $GroupComparison -eq 0 ]; then

  # This option should not be used as it does not adequately separate between- and within-subject variability!
	echo "Performing correlation analysis"
	
	echo "Severity: Linear"
	dOutput=$dOutput/3dLME_severity
	mkdir -p $dOutput
	dataTable=/project/3024006.02/Analyses/motor_task/Group/Longitudinal/AFNI/${con}_severity_dataTable2.txt
	cd $dOutput
	cp $mask $(pwd)/mask.nii
	cp $dataTable $(pwd)
	rm ${con}*.BRIK ${con}*.HEAD
	
	/opt/afni/2022/3dLMEr -prefix $dOutput/${con}_Severity2_x_Type3 -jobs $njobs \
	-resid $dOutput/${con}_Severity2_x_Type3_resid \
	-mask $mask \
	-model '1+ClinScore_brady_cb*trial_type+ClinScore_brady_cw*trial_type+ClinScore_cog_cb*trial_type+ClinScore_cog_cw*trial_type+Age+Sex+YearsSinceDiag.imp+NpsEducYears.imp+RespHandIsDominant+(1|Subj)' \
	-qVars 'ClinScore_brady_cb,ClinScore_brady_cw,ClinScore_cog_cb,ClinScore_cog_cw,Age,YearsSinceDiag.imp,NpsEducYears.imp' \
	-gltCode Type23gt1_by_Brady_cb 'trial_type : -1*1c 1*23c ClinScore_brady_cb :' \
	-gltCode Mean_by_Brady_cb 'ClinScore_brady_cb :' \
	-gltCode Type23gt1_by_Brady_cw 'trial_type : -1*1c 1*23c ClinScore_brady_cw :' \
	-gltCode Mean_by_Brady_cw 'ClinScore_brady_cw :' \
	-gltCode Type23gt1_by_Moca_cb 'trial_type : -1*1c 1*23c ClinScore_cog_cb :' \
	-gltCode Mean_by_Moca_cb 'ClinScore_cog_cb :' \
	-gltCode Type23gt1_by_Moca_cw 'trial_type : -1*1c 1*23c ClinScore_cog_cw :' \
	-gltCode Mean_by_Moca_cw 'ClinScore_cog_cw :' \
	-dataTable \
	`cat $dataTable`

fi
