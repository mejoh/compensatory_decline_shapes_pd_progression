#!/bin/bash

wd=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/wd
mkdir -p ${wd}
templatedir=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/templates
outdir=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results

# Construct basic masks
	# Bradykinesia + Cognitive composite
m1=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBoth-2gt1_Neg-Brady_Mask.nii
m2=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBoth-2gt1_Pos-CogCom_Mask.nii
m3=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBoth-3gt1_Neg-Brady_Mask.nii
m4=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBoth-3gt1_Neg-CogCom_Mask.nii
m5=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBoth-3gt1_Pos-CogCom_Mask.nii
fslmaths $m1 -add $m2 -add $m3 -add $m4 -add $m5 -bin -dilF $wd/ClinCorr_2scores_mask
	# Bradykinesia
m1=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBrady-2gt1_Neg_Mask.nii
m2=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBrady-3gt1_Neg_Mask.nii
m3=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrBrady-Mean_Neg_Mask.nii
fslmaths $m1 -add $m2 -add $m3 -bin -dilF $wd/ClinCorr_brady_mask
	# Cognitive composite
m1=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrCogCom-2gt1_Pos_Mask.nii
m2=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrCogCom-3gt1_Neg_Mask.nii
m3=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrCogCom-3gt1_Pos_Mask.nii
m4=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/corrCogCom-Mean_Pos_Mask.nii
fslmaths $m1 -add $m2 -add $m3 -add $m4 -bin -dilF $wd/ClinCorr_cogcom_mask
	# BG dysfunction
m1=/home/sysneu/marjoh/scripts/compensatory_decline_shapes_pd_progression/ROIs/Johansson2024_BRAIN_results/compHCgtOD_Mean_Mask.nii
fslmaths $m1 -bin $wd/HCgtPD_mean_mask

# Construct mask alternatives
m1=$wd/ClinCorr_2scores_mask.nii.gz
m2=$wd/ClinCorr_brady_mask.nii.gz
m3=$wd/ClinCorr_cogcom_mask.nii.gz
m4=$wd/HCgtPD_mean_mask.nii.gz
fslmaths $m2 -add $m4 -bin $wd/brady_clincorr_bg_mask
fslmaths $m3 -add $m4 -bin $wd/cogcom_clincorr_bg_mask

# Flip and add

for m in brady cogcom; do

	fslswapdim $wd/${m}_clincorr_bg_mask -x y z $wd/${m}_clincorr_bg_mask_flip

	fslmaths $wd/${m}_clincorr_bg_mask -add $wd/${m}_clincorr_bg_mask_flip -bin -dilF $wd/bi_${m}_clincorr_bg_mask

	3dresample -master $wd/bi_${m}_clincorr_bg_mask.nii.gz -prefix $wd/tpl-MNI152NLin6Asym_desc-brain_mask.nii -input $templatedir/tpl-MNI152NLin6Asym_res-02_desc-brain_mask.nii

	fslmaths $wd/bi_${m}_clincorr_bg_mask -mas $wd/tpl-MNI152NLin6Asym_desc-brain_mask.nii -fillh $wd/bi_${m}_clincorr_bg_mask_cropped

	immv $wd/bi_${m}_clincorr_bg_mask_cropped $outdir/bi_${m}_clincorr_bg_mask_cropped

	gunzip $outdir/bi_${m}_clincorr_bg_mask_cropped.nii.gz

done

fslmaths $outdir/bi_brady_clincorr_bg_mask_cropped.nii -add $outdir/bi_cogcom_clincorr_bg_mask_cropped.nii -bin $outdir/Johansson2024_BRAIN_ROIs
gunzip $outdir/Johansson2024_BRAIN_ROIs.nii.gz

# rm -r ${wd}



