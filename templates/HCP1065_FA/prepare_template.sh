#!/bin/bash

fslreorient2std /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA.nii.gz /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl.nii.gz

fslmaths /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl.nii.gz -thr 0.05 -bin /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_mask.nii.gz

fslmaths /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_mask.nii.gz -ero /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_mask_ero.nii.gz

3dresample -prefix /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_mask_ero_2mm.nii.gz -dxyz 2.000000 2.000000 2.000000 -inset /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_mask_ero.nii.gz

3dresample -prefix /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl_2mm.nii.gz -dxyz 2.000000 2.000000 2.000000 -inset /project/3024006.02/templates/template_50HC50PD/HCP1065_FA_template/T_HCP1065_FA_fsl.nii.gz
